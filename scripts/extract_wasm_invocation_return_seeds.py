#!/usr/bin/env python3
"""Split core .wast files into one seed per `assert_return` invocation.

Each generated seed has the shape

    [cross-module dependencies]      ; only when the target imports a registered module
    (module ...)                     ; mutation target
    (assert_return (invoke ...))     ; state-changing prefix, replayed with coverage OFF
    (assert_return (invoke ...) ...) ; final driver, the observed invocation

Seeds are validated by replaying them through the reference interpreter built
from the same tree as the test suite (not the one bundled with p4spec, which lags
the spec); only seeds it accepts are written to the output directory. Seeds
containing the `unreachable` instruction are excluded before replay, and the
manifest records the source tree's commit so the corpus can be reproduced.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

# Instructions that write to store-resident state.
MUTATING_INSTR = re.compile(
    r"(?<![\w.$])("
    r"global\.set|memory\.grow|memory\.fill|memory\.copy|memory\.init|"
    r"table\.set|table\.grow|table\.fill|table\.copy|table\.init|"
    r"[a-z0-9_]+\.store[0-9_a-z]*|struct\.set|array\.set|array\.fill|"
    r"array\.copy|array\.init[\w.]*"
    r")(?![\w.$])"
)

# Any call leaves the callee's effect unknown; treated as state-changing.
CALL_INSTR = re.compile(r"(?<![\w.$])(call_indirect|call_ref|return_call\w*|call)(?![\w.$])")

MODULE_KIND = re.compile(r"\(\s*module\s+(binary|quote|definition|instance)\b")
MODULE_ID = re.compile(r"\(\s*module(?:\s+(?:definition|instance))?\s+(\$[^\s)]+)")
MODULE_INSTANCE_OF = re.compile(r"\(\s*module\s+instance\s+(\$[^\s)]+)\s+(\$[^\s)]+)")
INVOKE_TARGET = re.compile(r'\(\s*invoke\s+(\$[^\s)]+)?\s*"((?:[^"\\]|\\.)*)"')
REGISTER_FORM = re.compile(r'\(\s*register\s+"((?:[^"\\]|\\.)*)"(?:\s+(\$[^\s)]+))?')
IMPORT_NAME = re.compile(r'\(\s*import\s+"((?:[^"\\]|\\.)*)"')
EXPORT_NAME = re.compile(r'\(\s*export\s+"((?:[^"\\]|\\.)*)"\s*\)')


TRAP_ASSERTION = re.compile(
    r"\(\s*(assert_trap|assert_exception|assert_exhaustion)\b"
)

# A seed must not contain the `unreachable` instruction anywhere, even in code
# the observed invocation never runs: a mutation that steers execution into it
# traps by design, which says nothing about the specification.
UNREACHABLE_INSTR = re.compile(r"(?<![\w.$])unreachable(?![\w.$])")


def code_and_strings(text: str) -> tuple[str, list[str]]:
    """Split WAT text into its code, with comments and strings blanked out,
    and the raw contents of its string literals."""
    code: list[str] = []
    strings: list[str] = []
    i, n = 0, len(text)
    while i < n:
        if text.startswith(";;", i):
            newline = text.find("\n", i)
            i = n if newline < 0 else newline + 1
            code.append(" ")
        elif text.startswith("(;", i):
            nesting, i = 1, i + 2
            while i < n and nesting:
                if text.startswith("(;", i):
                    nesting, i = nesting + 1, i + 2
                elif text.startswith(";)", i):
                    nesting, i = nesting - 1, i + 2
                else:
                    i += 1
            code.append(" ")
        elif text[i] == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            strings.append(text[i + 1 : j])
            code.append(' "" ')
            i = j + 1
        else:
            code.append(text[i])
            i += 1
    return "".join(code), strings


def decode_string(raw: str) -> str:
    """Decode the escapes of a WAT string literal (as text, bytes as latin-1)."""
    simple = {"t": "\t", "n": "\n", "r": "\r", '"': '"', "'": "'", "\\": "\\"}
    out: list[str] = []
    i = 0
    while i < len(raw):
        if raw[i] != "\\" or i + 1 >= len(raw):
            out.append(raw[i])
            i += 1
        elif raw[i + 1] in simple:
            out.append(simple[raw[i + 1]])
            i += 2
        elif raw.startswith("u{", i + 1):
            close = raw.find("}", i)
            out.append(chr(int(raw[i + 3 : close].replace("_", ""), 16)))
            i = close + 1
        else:
            out.append(chr(int(raw[i + 1 : i + 3], 16)))
            i += 3
    return "".join(out)


_binary_text_cache: dict[str, str | None] = {}


def binary_module_text(form: str, interpreter: pathlib.Path) -> str | None:
    """Print a binary module as text with the reference interpreter; None if it
    cannot be decoded (reference replay then rejects the seed anyway)."""
    if form not in _binary_text_cache:
        with tempfile.TemporaryDirectory() as scratch:
            source = pathlib.Path(scratch) / "module.wast"
            printed = pathlib.Path(scratch) / "module.wat"
            source.write_text(form + "\n", encoding="utf-8")
            completed = subprocess.run(
                [str(interpreter), "-d", str(source), "-o", str(printed)],
                check=False, capture_output=True, text=True,
            )
            _binary_text_cache[form] = (
                printed.read_text(encoding="utf-8", errors="replace")
                if completed.returncode == 0 and printed.exists() else None
            )
    return _binary_text_cache[form]


def contains_unreachable(text: str, interpreter: pathlib.Path | None) -> bool:
    """Whether any module of a rendered seed contains `unreachable`. Quoted
    modules are checked in their decoded text and binary modules in the text the
    reference interpreter prints for them."""
    for start, end, head in split_top_level(text):
        form = text[start : end + 1]
        code, strings = code_and_strings(form)
        if UNREACHABLE_INSTR.search(code):
            return True
        if head != "module":
            continue
        kind_match = MODULE_KIND.match(form)
        kind = kind_match.group(1) if kind_match else "text"
        if kind == "quote":
            quoted = "".join(decode_string(raw) for raw in strings)
            if UNREACHABLE_INSTR.search(code_and_strings(quoted)[0]):
                return True
        elif kind == "binary":
            if interpreter is None:
                raise OSError("a binary module needs the reference interpreter "
                              "to be checked for unreachable")
            printed = binary_module_text(form, interpreter)
            if printed and UNREACHABLE_INSTR.search(code_and_strings(printed)[0]):
                return True
    return False

# Files Wasm-SpecTec's own AL interpreter skips as too slow to interpret
# (spectec/src/backend-interpreter/runner.ml, is_long_test). Their invocations
# run counts like `(i64.const 1_000_000)`, which a real engine finishes at once
# but an interpreted specification does not.
LONG_TEST_SOURCES = {
    "memory_copy.wast",
    "memory_copy64.wast",
    "memory_fill.wast",
    "memory_fill64.wast",
    "memory_grow.wast",
    "memory_grow64.wast",
    "call_indirect.wast",
    "call_indirect64.wast",
    "return_call.wast",
    "return_call_indirect.wast",
    "return_call_ref.wast",
}


def seed_prefix(source: pathlib.Path, source_root: pathlib.Path) -> str:
    """Seed name stem. Top-level sources keep their bare stem; files in a
    proposal subdirectory are prefixed with it so basenames cannot collide
    (e.g. memory_grow.wast exists both at the root and under multi-memory/)."""
    rel = source.relative_to(source_root)
    if rel.parent == pathlib.Path("."):
        return source.stem
    return f"{rel.parent.as_posix().replace('/', '-')}-{source.stem}"


class WastParseError(Exception):
    pass


def split_top_level(text: str) -> list[tuple[int, int, str]]:
    """Return (start, end_inclusive, head) for every top-level s-expression."""
    forms: list[tuple[int, int, str]] = []
    i, n, depth, start = 0, len(text), 0, None
    while i < n:
        if text.startswith(";;", i):
            newline = text.find("\n", i)
            i = n if newline < 0 else newline + 1
            continue
        if text.startswith("(;", i):
            nesting = 1
            i += 2
            while i < n and nesting:
                if text.startswith("(;", i):
                    nesting += 1
                    i += 2
                elif text.startswith(";)", i):
                    nesting -= 1
                    i += 2
                else:
                    i += 1
            continue
        char = text[i]
        if char == '"':
            i += 1
            while i < n:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        if char == "(":
            if depth == 0:
                start = i
            depth += 1
        elif char == ")":
            depth -= 1
            if depth < 0:
                raise WastParseError(f"unbalanced ')' at offset {i}")
            if depth == 0 and start is not None:
                segment = text[start : i + 1]
                head = re.match(r"\(\s*([A-Za-z_][\w.$]*)", segment)
                forms.append((start, i, head.group(1) if head else ""))
                start = None
        i += 1
    if depth:
        raise WastParseError("unterminated s-expression")
    return forms


def exported_function_bodies(module_text: str) -> dict[str, str]:
    """Map each exported name to the text of the `(func ...)` form declaring it."""
    bodies: dict[str, str] = {}
    for match in re.finditer(r"\(\s*func\b", module_text):
        start = match.start()
        i, n, depth = start, len(module_text), 0
        while i < n:
            char = module_text[i]
            if char == '"':
                i += 1
                while i < n:
                    if module_text[i] == "\\":
                        i += 2
                        continue
                    if module_text[i] == '"':
                        i += 1
                        break
                    i += 1
                continue
            if char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        body = module_text[start : i + 1]
        for export in EXPORT_NAME.finditer(body):
            bodies[export.group(1)] = body
    return bodies


def export_changes_state(bodies: dict[str, str], name: str) -> bool:
    """Conservative: unknown exports and any call are treated as state-changing."""
    body = bodies.get(name)
    if body is None:
        return True
    return bool(MUTATING_INSTR.search(body)) or bool(CALL_INSTR.search(body))


class Instance:
    """A module form together with the invocations replayed against it."""

    __slots__ = ("span", "index", "kind", "bodies", "imports", "invokes", "extra_spans")

    def __init__(self, span, index, kind, bodies, imports, extra_spans=()):
        self.span = span
        self.index = index
        self.kind = kind
        self.bodies = bodies
        self.imports = imports
        # `(module instance $I $M)` must be emitted alongside its definition.
        self.extra_spans = tuple(extra_spans)
        self.invokes: list[tuple[tuple[int, int], str]] = []


class Seed:
    __slots__ = ("index", "instance", "export", "prefix_spans", "aux_spans",
                 "final_span", "preceding_spans")

    def __init__(self, index, instance, export, prefix_spans, aux_spans, final_span,
                 preceding_spans):
        self.index = index
        self.instance = instance
        self.export = export
        self.prefix_spans = prefix_spans
        self.aux_spans = aux_spans
        self.final_span = final_span
        self.preceding_spans = preceding_spans


def resolve_dependencies(instance: Instance,
                         registry: dict[str, tuple[Instance, tuple[int, int]]]
                         ) -> list[tuple[int, int]]:
    """Transitively collect the forms the target links against.

    A provider contributes its module form, its register form, and any invocation
    that already changed its state: an importer may depend on the grown/mutated
    shape of the provider, not just on its definition.
    """
    spans: set[tuple[int, int]] = set()
    seen: set[int] = {id(instance)}
    worklist = [instance]
    while worklist:
        current = worklist.pop()
        for name in current.imports:
            if name == "spectest" or name not in registry:
                continue
            provider, register_span = registry[name]
            spans.add(register_span)
            if id(provider) in seen:
                continue
            seen.add(id(provider))
            spans.add(provider.span)
            for invoke_span, invoked in provider.invokes:
                if export_changes_state(provider.bodies, invoked):
                    spans.add(invoke_span)
            worklist.append(provider)
    return sorted(spans)


def collect_seeds(text: str) -> list[Seed]:
    forms = split_top_level(text)
    seeds: list[Seed] = []
    named: dict[str, Instance] = {}
    registry: dict[str, tuple[Instance, tuple[int, int]]] = {}
    current: Instance | None = None
    module_index = -1
    preceding: list[tuple[int, int]] = []

    def target_for(module_ref: str | None) -> Instance | None:
        if module_ref is None:
            return current
        return named.get(module_ref)

    def note_invoke(instance: Instance, span, export: str) -> None:
        instance.invokes.append((span, export))

    for start, end, head in forms:
        segment = text[start : end + 1]
        span = (start, end)
        # Recorded before any branch bails out, so the full-replay fallback keeps
        # forms this walk does not model (module instances, non-invoke actions).
        preceding.append(span)

        if head == "module":
            kind_match = MODULE_KIND.match(segment)
            kind = kind_match.group(1) if kind_match else "text"
            if kind == "instance":
                link = MODULE_INSTANCE_OF.match(segment)
                if link and link.group(2) in named:
                    definition = named[link.group(2)]
                    instance = Instance(definition.span, definition.index,
                                        definition.kind, definition.bodies,
                                        definition.imports,
                                        (*definition.extra_spans, span))
                    named[link.group(1)] = instance
                    current = instance
                continue
            module_index += 1
            instance = Instance(span, module_index, kind,
                                exported_function_bodies(segment),
                                set(IMPORT_NAME.findall(segment)))
            identifier = MODULE_ID.match(segment)
            if identifier:
                named[identifier.group(1)] = instance
            if kind != "definition":
                current = instance

        elif head == "register":
            registered = REGISTER_FORM.match(segment)
            if registered:
                provider = target_for(registered.group(2))
                if provider is not None:
                    registry[registered.group(1)] = (provider, span)

        elif head == "assert_return":
            invocation = INVOKE_TARGET.search(segment)
            if invocation is None:
                continue  # (assert_return (get ...) ...) and friends
            instance = target_for(invocation.group(1))
            if instance is None:
                continue
            export = invocation.group(2)
            prefix = [
                invoke_span
                for (invoke_span, name) in instance.invokes
                if export_changes_state(instance.bodies, name)
            ]
            seeds.append(
                Seed(
                    index=len(seeds),
                    instance=instance,
                    export=export,
                    prefix_spans=prefix,
                    aux_spans=resolve_dependencies(instance, registry),
                    final_span=span,
                    preceding_spans=list(preceding),
                )
            )
            note_invoke(instance, span, export)

        elif head == "invoke":
            invocation = INVOKE_TARGET.search(segment)
            if invocation is None:
                continue
            instance = target_for(invocation.group(1))
            if instance is not None:
                note_invoke(instance, span, invocation.group(2))
        # assert_trap / assert_exception / assert_exhaustion are deliberately not
        # recorded: a seed must be a program that returns values, so that mutating
        # it into one that traps or gets stuck is the signal. Seeds that turn out
        # to need such a command for their state are rejected below.

    return seeds


def render_seed(text: str, seed: Seed) -> str:
    # Source order is replay order: a provider invoked after the target was
    # defined must still be replayed at its original position.
    spans = sorted(
        {seed.instance.span, seed.final_span, *seed.instance.extra_spans,
         *seed.aux_spans, *seed.prefix_spans}
    )
    return "\n\n".join(text[s : e + 1] for (s, e) in spans) + "\n"


def render_seed_full_replay(text: str, seed: Seed) -> str:
    """Fallback: replay the whole file up to the observed invocation.

    Some dependencies are not carried by invocations at all — instantiating a
    module can mutate a table or memory it imports from an earlier module — so
    when the precise slice is rejected, fall back to reproducing the original
    prefix verbatim.
    """
    spans = sorted({*seed.preceding_spans, seed.final_span})
    return "\n\n".join(text[s : e + 1] for (s, e) in spans) + "\n"


def source_provenance(source_root: pathlib.Path) -> tuple[str | None, bool | None]:
    """The commit of the git tree holding the test suite, and whether the suite
    has local changes; (None, None) outside a git checkout."""
    def git(*args: str) -> subprocess.CompletedProcess:
        return subprocess.run(["git", "-C", str(source_root), *args],
                              check=False, capture_output=True, text=True)
    head = git("rev-parse", "HEAD")
    if head.returncode != 0:
        return None, None
    status = git("status", "--porcelain", "--", ".")
    return head.stdout.strip(), bool(status.stdout.strip())


def reference_replay(interpreter: pathlib.Path, path: pathlib.Path,
                     timeout_seconds: float) -> tuple[bool, int, str]:
    try:
        completed = subprocess.run(
            [str(interpreter), str(path)],
            check=False, capture_output=True, text=True, timeout=timeout_seconds,
        )
        return completed.returncode == 0, completed.returncode, completed.stderr[-2000:]
    except subprocess.TimeoutExpired:
        return False, 124, "reference replay timed out"


def generate(source_root: pathlib.Path, output_dir: pathlib.Path,
             interpreter: pathlib.Path, timeout_seconds: float, jobs: int,
             verify: bool, clean: bool, limit: int | None) -> dict:
    # proposal suites live in subdirectories (memory64/, multi-memory/, simd/, ...);
    # they carry assert_return invocations too, so walk the tree.
    sources = sorted(
        p for p in source_root.rglob("*.wast")
        if "_output" not in p.relative_to(source_root).parts
    )
    if not sources:
        raise OSError(f"no .wast files under {source_root}")
    if output_dir.exists():
        if not clean:
            raise FileExistsError(f"{output_dir} already exists; pass --clean to replace")
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)

    candidates: list[tuple[str, str, dict, str, Seed]] = []
    excluded_entries: list[dict] = []
    checker = interpreter if interpreter.exists() else None
    parse_failures: list[dict] = []
    skipped_sources: list[str] = []
    for source in sources:
        rel = source.relative_to(source_root)
        if source.name in LONG_TEST_SOURCES:
            skipped_sources.append(rel.as_posix())
            continue
        text = source.read_text(encoding="utf-8", errors="replace")
        try:
            seeds = collect_seeds(text)
        except WastParseError as error:
            parse_failures.append({"source": rel.as_posix(), "error": str(error)})
            continue
        for seed in seeds:
            filename = f"{seed_prefix(source, source_root)}_{seed.index}.wast"
            entry = {
                "seed": filename,
                "source": rel.as_posix(),
                "source_index": seed.index,
                "module_index": seed.instance.index,
                "module_kind": seed.instance.kind,
                "export": seed.export,
                "prefix_invocations": len(seed.prefix_spans),
                "dependency_forms": len(seed.aux_spans),
                "render_mode": "sliced",
            }
            content = render_seed(text, seed)
            if contains_unreachable(content, checker):
                entry["status"] = "excluded-unreachable"
                excluded_entries.append(entry)
                continue
            candidates.append((filename, content, entry, text, seed))
            if limit and len(candidates) >= limit:
                break
        if limit and len(candidates) >= limit:
            break

    entries: list[dict] = list(excluded_entries)
    excluded = len(excluded_entries)
    accepted = 0
    rejected = 0

    recovered = 0

    if not verify:
        for filename, content, entry, _text, _seed in candidates:
            (output_dir / filename).write_text(content, encoding="utf-8")
            entry["status"] = "written-unverified"
            entries.append(entry)
            accepted += 1
    else:
        with tempfile.TemporaryDirectory() as staging_root:
            staging = pathlib.Path(staging_root)

            def check(item):
                filename, content, entry, text, seed = item
                path = staging / filename
                path.write_text(content, encoding="utf-8")
                passed, returncode, stderr = reference_replay(interpreter, path, timeout_seconds)
                if not passed:
                    fallback = render_seed_full_replay(text, seed)
                    if TRAP_ASSERTION.search(fallback):
                        return item, False, returncode, stderr, None
                    if contains_unreachable(fallback, checker):
                        # returncode None marks the exclusion for the caller
                        return item, False, None, "full replay contains unreachable", None
                    if fallback != content:
                        path.write_text(fallback, encoding="utf-8")
                        passed, returncode, stderr = reference_replay(
                            interpreter, path, timeout_seconds
                        )
                        if passed:
                            return item, True, returncode, stderr, fallback
                return item, passed, returncode, stderr, None

            with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
                for item, passed, returncode, stderr, fallback in pool.map(check, candidates):
                    filename, content, entry, _text, _seed = item
                    if passed:
                        if fallback is not None:
                            content = fallback
                            entry["render_mode"] = "full-replay"
                            recovered += 1
                        (output_dir / filename).write_text(content, encoding="utf-8")
                        entry["status"] = "accepted"
                        accepted += 1
                    elif returncode is None:
                        entry["status"] = "excluded-unreachable"
                        excluded += 1
                    else:
                        entry.update({
                            "status": "rejected-by-reference",
                            "reference_returncode": returncode,
                            "reference_stderr": stderr,
                        })
                        rejected += 1
                    entries.append(entry)

    entries.sort(key=lambda e: (e["source"], e["source_index"]))
    source_commit, source_dirty = source_provenance(source_root)
    manifest = {
        "source_root": str(source_root),
        "source_commit": source_commit,
        "source_dirty": source_dirty,
        "output_dir": str(output_dir),
        "reference_interpreter": str(interpreter) if verify else None,
        "verified": verify,
        "source_file_count": len(sources),
        "candidate_count": len(candidates) + len(excluded_entries),
        "excluded_unreachable_count": excluded,
        "accepted_count": accepted,
        "rejected_count": rejected,
        "full_replay_count": recovered,
        "skipped_long_tests": sorted(skipped_sources),
        "parse_failures": parse_failures,
        "entries": entries,
    }
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(
        description="split core .wast files into one seed per assert_return invocation"
    )
    parser.add_argument("--source-root", default=str(pathlib.Path.home() / "Workspace/wasm-spectec/test/core"))
    parser.add_argument("--output-dir", default="test-invocation-return")
    # The bundled p4spec interpreter lags the spec; validate against the
    # interpreter built from the same tree as the test suite.
    parser.add_argument(
        "--reference-interpreter",
        default=str(pathlib.Path.home() / "Workspace/wasm-spectec/interpreter/wasm"),
    )
    parser.add_argument("--reference-timeout", type=float, default=30.0)
    parser.add_argument("--jobs", type=int, default=8)
    parser.add_argument("--no-verify", action="store_true", help="skip reference interpreter replay")
    parser.add_argument("--clean", action="store_true", help="replace the output directory")
    parser.add_argument("--limit", type=int, default=None, help="stop after N candidates (smoke test)")
    args = parser.parse_args()

    try:
        manifest = generate(
            source_root=pathlib.Path(args.source_root).expanduser(),
            output_dir=pathlib.Path(args.output_dir),
            interpreter=pathlib.Path(args.reference_interpreter),
            timeout_seconds=args.reference_timeout,
            jobs=args.jobs,
            verify=not args.no_verify,
            clean=args.clean,
            limit=args.limit,
        )
    except (FileExistsError, OSError, WastParseError) as error:
        parser.exit(1, f"error: {error}\n")

    print(
        f"candidates {manifest['candidate_count']} from {manifest['source_file_count']} files; "
        f"accepted {manifest['accepted_count']} "
        f"({manifest['full_replay_count']} via full replay), "
        f"rejected {manifest['rejected_count']}, "
        f"excluded for unreachable {manifest['excluded_unreachable_count']}"
    )
    if manifest["parse_failures"]:
        print(f"parse failures: {len(manifest['parse_failures'])}")
    if manifest["source_commit"]:
        dirty = " (with local changes)" if manifest["source_dirty"] else ""
        print(f"source commit {manifest['source_commit']}{dirty}")
    print(f"wrote {pathlib.Path(args.output_dir) / 'manifest.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
