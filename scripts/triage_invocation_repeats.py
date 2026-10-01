#!/usr/bin/env python3
"""Triage invocation-phase findings with the reference interpreter.

An invocation-phase finding is a script whose last invocation got stuck under
spec-wasm-no-trap after its target module passed Module_ok. Most are ordinary
traps. The ones worth a look are those the reference interpreter rejects at
validation (validation soundness bug candidates) or runs to a different end.

The script scans <campaign>/trapped/*.wast (first hits) and
<campaign>/repeat/<iid>/*.wast (repeat hits), runs the reference interpreter of
a wasm-spectec checkout on each, and writes triage.csv and summary.txt.

Usage:
  python3 scripts/triage_invocation_repeats.py CAMPAIGN [CAMPAIGN ...]
      [--wasm-spectec DIR] [--out DIR] [--jobs N] [--timeout S] [--spec-check]

CAMPAIGN is the directory that holds trapped/ and repeat/, i.e. <gen-dir>/<name>
of wasm-testgen; single .wast files are accepted too. The reference interpreter
is DIR/interpreter/wasm, with DIR defaulting to ~/Workspace/wasm-spectec.

Outcomes and verdicts (validation runs first with `wasm -d`, then the whole
script runs with `wasm -t`):
  reference-invalid             candidate     reference rejects the target module
  reference-no-trap             candidate     final invocation returns normally
  reference-exception           candidate     final invocation throws
  reference-crash               candidate     reference crashes
  reference-instantiation-trap  candidate     target instantiation traps
  reference-link-failure        candidate     target does not link
  reference-trap                benign        final invocation traps (ordinary trap)
  reference-script-error        benign        invoke arguments or export do not match
  reference-exhaustion          inconclusive  call stack exhaustion
  prefix-invalid                inconclusive  a module before the target is rejected
  replay-failure                inconclusive  a command before the final one fails
  reference-parse-error         inconclusive  the artifact does not parse
  reference-timeout             inconclusive  no answer within --timeout
  reference-fatal               inconclusive  uncaught OCaml exception (e.g. out of memory)
  reference-other               inconclusive  anything else

With --spec-check, each artifact is also run by wasm-ntt's P4-SpecTec with the
unmodified spec-wasm (run-wasm -rel Scripts_init_ok). "trap" there means the
assert_trap holds under the specification with its trap rules.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import csv
import datetime
import json
import os
import re
import subprocess
import sys
import time
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DEFAULT_WASM_SPECTEC = Path.home() / "Workspace" / "wasm-spectec"

VERDICTS = {
    "reference-invalid": "candidate",
    "reference-no-trap": "candidate",
    "reference-exception": "candidate",
    "reference-crash": "candidate",
    "reference-instantiation-trap": "candidate",
    "reference-link-failure": "candidate",
    "reference-trap": "benign",
    "reference-script-error": "benign",
    "reference-exhaustion": "inconclusive",
    "prefix-invalid": "inconclusive",
    "replay-failure": "inconclusive",
    "reference-parse-error": "inconclusive",
    "reference-timeout": "inconclusive",
    "reference-fatal": "inconclusive",
    "reference-other": "inconclusive",
}

VERDICT_ORDER = ["candidate", "benign", "inconclusive"]

CSV_FIELDS = [
    "artifact",
    "source",
    "repeat_iid",
    "intended_iid",
    "hit_iids",
    "seed",
    "fuel",
    "mutation",
    "verdict",
    "outcome",
    "stage",
    "category",
    "location",
    "message",
    "reference_seconds",
    "spec_wasm",
    "spec_wasm_message",
]

# <seed>_F<fuel>P<iid>S<seed index><D|R><method>M<mutation>T<trial>.wast
ARTIFACT_NAME = re.compile(
    r"^(?P<seed>.+)_F(?P<fuel>\d+)P(?P<iid>\d+)S\d+[DR]?\d+M\d+T\d+\.wast$"
)
INTENDED = re.compile(r"^;; Intended iid (\d+)$", re.MULTILINE)
MUTATION = re.compile(r"^;; Mutation (.+)$", re.MULTILINE)
HITS = re.compile(r"^;; (?:Covered|Repeat hit) iids \{([^}]*)\}\s*$", re.MULTILINE)
HEAD = re.compile(r"\(\s*([^\s()\";]+)(?:\s+([^\s()\";]+))?")
ERROR = re.compile(
    r"^(?P<file>.+?):(?P<line>\d+)\.(?P<column>\d+)(?:-(?P<line2>\d+)\.(?P<column2>\d+))?"
    r": (?P<category>[a-z/ ]+?): (?P<message>.*)$"
)
FILE_ERROR = re.compile(r"^(?P<file>.+?): (?P<category>[a-z/ ]+?): (?P<message>.*)$")


# Script structure


@dataclass
class Form:
    head: str
    first_line: int
    last_line: int
    second: str = ""  # the token after the head, e.g. `instance` in (module instance ...)


def top_level_forms(text: str) -> list[Form]:
    """Top-level s-expressions with their 1-based line spans, lexed like Wasm
    text: `;;` line comments, nested `(; ;)` block comments, and strings with
    backslash escapes."""
    forms: list[Form] = []
    depth = 0
    line = 1
    start_line = 0
    head = second = ""
    index = 0
    length = len(text)
    while index < length:
        char = text[index]
        if char == "\n":
            line += 1
            index += 1
        elif text.startswith(";;", index):
            end = text.find("\n", index)
            index = length if end < 0 else end
        elif text.startswith("(;", index):
            level = 1
            index += 2
            while index < length and level > 0:
                if text.startswith("(;", index):
                    level += 1
                    index += 2
                elif text.startswith(";)", index):
                    level -= 1
                    index += 2
                else:
                    if text[index] == "\n":
                        line += 1
                    index += 1
        elif char == '"':
            index += 1
            while index < length and text[index] != '"':
                if text[index] == "\\":
                    index += 1
                if index < length and text[index] == "\n":
                    line += 1
                index += 1
            index += 1
        elif char == "(":
            if depth == 0:
                start_line = line
                match = HEAD.match(text, index)
                head = match.group(1) if match else ""
                second = (match.group(2) or "") if match else ""
            depth += 1
            index += 1
        elif char == ")":
            # An unmatched parenthesis is a syntax error for the reference;
            # skipping it keeps the later forms
            if depth > 0:
                depth -= 1
                if depth == 0:
                    forms.append(Form(head, start_line, line, second))
            index += 1
        else:
            index += 1
    return forms


@dataclass
class Layout:
    """Where the parts of a rendered invocation artifact are: the target module
    is its last module, and the stuck invocation is its last command."""

    modules: int  # modules the reference validates
    assertions: int
    target: Form | None
    final: Form | None

    @staticmethod
    def of_text(text: str) -> "Layout":
        forms = top_level_forms(text)
        modules = [form for form in forms if form.head == "module"]
        # (module instance ...) instantiates a definition without validating it
        checked = [form for form in modules if form.second != "instance"]
        return Layout(
            modules=len(checked),
            assertions=sum(1 for form in forms if form.head.startswith("assert_")),
            target=modules[-1] if modules else None,
            final=forms[-1] if forms else None,
        )

    def region(self, line: int | None) -> str:
        def within(form: Form | None) -> bool:
            return (
                form is not None
                and line is not None
                and form.first_line <= line <= form.last_line
            )

        if within(self.final):
            return "final"
        if within(self.target):
            return "target"
        if line is None or self.target is None:
            return "unknown"
        return "prefix" if line < self.target.first_line else "replay"


# Reference interpreter output


@dataclass
class ReferenceError:
    category: str
    message: str
    line: int | None = None
    location: str = ""


def parse_reference_error(stderr: str, artifact: Path) -> ReferenceError | None:
    """The first error the reference interpreter reports about the artifact."""
    for raw in stderr.splitlines():
        text = raw.strip()
        if not text.startswith(str(artifact)):
            # The interpreter itself died, e.g. "wasm: uncaught exception Out_of_memory"
            if ": uncaught exception " in text:
                return ReferenceError("fatal", text.split(": uncaught exception ", 1)[1].strip())
            continue
        match = ERROR.match(text)
        if match:
            location = f"{match['line']}.{match['column']}"
            if match["line2"]:
                location += f"-{match['line2']}.{match['column2']}"
            return ReferenceError(
                match["category"], match["message"], int(match["line"]), location
            )
        match = FILE_ERROR.match(text)
        if match:
            return ReferenceError(match["category"], match["message"])
    return None


@dataclass
class Stage:
    """The command the reference interpreter was running when it stopped, read
    from its -t trace of the artifact."""

    kind: str  # check, init, register, assert, action, or none
    checked: int = 0  # modules validated so far
    asserted: int = 0  # assertions started so far


def last_stage(trace: str, artifact: Path) -> Stage:
    stage = Stage("none")
    inside = False
    previous_assert = False
    for raw in trace.splitlines():
        if not raw.startswith("-- "):
            continue
        line = raw[3:]
        if line.startswith("Loading (") and str(artifact) in line:
            inside = True
            continue
        if not inside:
            continue
        if line.startswith("Error:"):
            break
        if line.startswith("Checking..."):
            stage = Stage("check", stage.checked + 1, stage.asserted)
            previous_assert = False
        elif line.startswith("Initializing..."):
            stage = Stage("init", stage.checked, stage.asserted)
            previous_assert = False
        elif line.startswith("Registering module"):
            stage = Stage("register", stage.checked, stage.asserted)
            previous_assert = False
        elif line.startswith("Asserting"):
            stage = Stage("assert", stage.checked, stage.asserted + 1)
            previous_assert = True
        elif line.startswith("Invoking function") or line.startswith("Getting global"):
            # The invocation an assertion wraps belongs to that assertion
            if not previous_assert:
                stage = Stage("action", stage.checked, stage.asserted)
            previous_assert = False
    return stage


def classify_validation(error: ReferenceError | None, stage: Stage, layout: Layout) -> str | None:
    """Outcome of the validation-only run, or None when every module is valid."""
    if error is None:
        return None
    if error.category == "fatal":
        return "reference-fatal"
    if error.category in ("syntax error", "decoding error", "custom annotation syntax error"):
        return "reference-parse-error"
    if error.category in ("validation error", "custom validation error"):
        if stage.kind == "check" and stage.checked == layout.modules:
            return "reference-invalid"
        if stage.kind == "check":
            return "prefix-invalid"
        region = layout.region(error.line)
        return "reference-invalid" if region == "target" else "prefix-invalid"
    return "reference-other"


def classify_run(error: ReferenceError | None, stage: Stage, layout: Layout) -> str:
    """Outcome of running the whole script after validation passed."""
    if error is None:
        return "reference-other"
    if error.category == "fatal":
        return "reference-fatal"
    if error.category == "script error":
        return "reference-script-error"
    if error.category in ("syntax error", "decoding error"):
        return "reference-parse-error"
    all_modules_checked = stage.checked == layout.modules
    if stage.kind == "assert" and stage.asserted == layout.assertions and all_modules_checked:
        if error.category == "assertion failure" and error.message.startswith(
            "expected runtime error"
        ):
            return "reference-no-trap"
        if error.category == "uncaught exception":
            return "reference-exception"
        if error.category == "runtime crash":
            return "reference-crash"
        if error.category == "resource exhaustion":
            return "reference-exhaustion"
        return "reference-other"
    if stage.kind == "init" and all_modules_checked:
        if error.category in ("runtime trap", "uncaught exception"):
            return "reference-instantiation-trap"
        if error.category == "link failure":
            return "reference-link-failure"
        if error.category == "runtime crash":
            return "reference-crash"
        if error.category == "resource exhaustion":
            return "reference-exhaustion"
        return "reference-other"
    if error.category == "validation error":
        return "reference-invalid" if all_modules_checked else "prefix-invalid"
    return "replay-failure"


# Running the tools


@dataclass
class Completed:
    returncode: int | None  # None on timeout
    stdout: str
    stderr: str
    seconds: float


def run(command: list[str], timeout: float, cwd: Path | None = None) -> Completed:
    start = time.monotonic()
    try:
        done = subprocess.run(
            command,
            cwd=cwd,
            capture_output=True,
            text=True,
            errors="replace",
            timeout=timeout,
        )
        return Completed(done.returncode, done.stdout, done.stderr, time.monotonic() - start)
    except subprocess.TimeoutExpired as expired:
        def text(value):
            if value is None:
                return ""
            return value.decode(errors="replace") if isinstance(value, bytes) else value

        return Completed(None, text(expired.stdout), text(expired.stderr), time.monotonic() - start)


@dataclass
class Artifact:
    path: Path
    source: str  # trapped or repeat
    repeat_iid: str = ""
    intended_iid: str = ""
    hit_iids: str = ""
    seed: str = ""
    fuel: str = ""
    mutation: str = ""
    layout: Layout | None = None


@dataclass
class Result:
    artifact: Artifact
    outcome: str
    stage: str = ""
    error: ReferenceError | None = None
    seconds: float = 0.0
    spec_wasm: str = ""
    spec_wasm_message: str = ""


def describe(path: Path, source: str, repeat_iid: str = "") -> Artifact:
    text = path.read_text(errors="replace")
    artifact = Artifact(path, source, repeat_iid)
    if match := INTENDED.search(text):
        artifact.intended_iid = match.group(1)
    if match := MUTATION.search(text):
        artifact.mutation = match.group(1).strip()
    if match := HITS.search(text):
        artifact.hit_iids = " ".join(match.group(1).replace(",", " ").split())
    if match := ARTIFACT_NAME.match(path.name):
        artifact.seed = match["seed"]
        artifact.fuel = match["fuel"]
    artifact.layout = Layout.of_text(text)
    return artifact


def collect(paths: list[Path], only: str) -> list[Artifact]:
    artifacts: list[Artifact] = []
    for path in paths:
        if path.is_file():
            source = "repeat" if path.parent.parent.name == "repeat" else "trapped"
            repeat_iid = path.parent.name if source == "repeat" else ""
            artifacts.append(describe(path, source, repeat_iid))
            continue
        if only in ("all", "trapped"):
            for wast in sorted((path / "trapped").glob("*.wast")):
                artifacts.append(describe(wast, "trapped"))
        if only in ("all", "repeat"):
            repeat = path / "repeat"
            directories = [d for d in repeat.iterdir() if d.is_dir()] if repeat.is_dir() else []
            by_iid = lambda d: (0, int(d.name)) if d.name.isdigit() else (1, d.name)
            for directory in sorted(directories, key=by_iid):
                for wast in sorted(directory.glob("*.wast")):
                    artifacts.append(describe(wast, "repeat", directory.name))
    return artifacts


def first_line(text: str, limit: int = 300) -> str:
    for line in text.splitlines():
        if line.strip():
            return line.strip()[:limit]
    return ""


def spec_check(artifact: Artifact, options) -> tuple[str, str]:
    specs = sorted(str(path) for path in options.spec_dir.glob("*.watsup"))
    command = [str(options.p4spectec), "run-wasm", *specs, "-rel", "Scripts_init_ok", "-w", str(artifact.path)]
    done = run(command, options.spec_timeout, cwd=options.wasm_ntt)
    if done.returncode is None:
        return "timeout", ""
    lines = [line for line in done.stdout.splitlines() if line.strip()]
    for index, line in enumerate(lines):
        if line == "Passed":
            return "trap", ""
        if line.startswith("Failed (runtime error):"):
            # The failure and its innermost cause, without the derivation tree
            causes = [rest.strip("└─│ ") for rest in lines[index + 1:]]
            causes = [cause for cause in causes if cause and not cause.startswith("spec-wasm")]
            detail = line.split(":", 1)[1].strip()
            if causes:
                detail += " / " + causes[-1]
            return "fail-runtime", detail[:300]
        if line.startswith("Failed (syntax error):"):
            return "fail-syntax", line.split(":", 1)[1].strip()[:300]
        if line.startswith("Unexpected pass"):
            return "unexpected-pass", ""
        if line.startswith("Expected fail"):
            return "expected-fail", ""
    return "error", first_line(done.stdout + "\n" + done.stderr)


def triage(artifact: Artifact, options) -> Result:
    layout = artifact.layout
    interpreter = str(options.reference_interpreter)
    started = time.monotonic()
    dry = run([interpreter, "-d", "-t", str(artifact.path)], options.timeout)
    if dry.returncode is None:
        result = Result(artifact, "reference-timeout", "validate")
    else:
        error = parse_reference_error(dry.stderr, artifact.path)
        if dry.returncode != 0 and error is None:
            error = ReferenceError("fatal", first_line(dry.stderr) or f"exit {dry.returncode}")
        outcome = classify_validation(error, last_stage(dry.stdout, artifact.path), layout)
        if outcome is not None:
            result = Result(artifact, outcome, "validate", error)
        else:
            full = run([interpreter, "-t", str(artifact.path)], options.timeout)
            if full.returncode is None:
                result = Result(artifact, "reference-timeout", "run")
            elif full.returncode == 0:
                result = Result(artifact, "reference-trap", "run")
            else:
                error = parse_reference_error(full.stderr, artifact.path)
                if error is None:
                    error = ReferenceError("fatal", first_line(full.stderr) or f"exit {full.returncode}")
                stage = last_stage(full.stdout, artifact.path)
                result = Result(artifact, classify_run(error, stage, layout), "run", error)
    result.seconds = time.monotonic() - started
    if options.spec_check:
        result.spec_wasm, result.spec_wasm_message = spec_check(artifact, options)
    return result


# Reporting


def display_root(campaigns: list[Path]) -> Path:
    """Artifact paths are shown relative to the one campaign, or to the common
    ancestor of several so that equally named campaigns stay apart."""
    if len(campaigns) == 1 and campaigns[0].is_dir():
        return campaigns[0]
    return Path(os.path.commonpath([p if p.is_dir() else p.parent for p in campaigns]))


def row_of(result: Result, root: Path) -> dict:
    artifact = result.artifact
    error = result.error
    try:
        shown = str(artifact.path.relative_to(root))
    except ValueError:
        shown = str(artifact.path)
    return {
        "artifact": shown,
        "source": artifact.source,
        "repeat_iid": artifact.repeat_iid,
        "intended_iid": artifact.intended_iid,
        "hit_iids": artifact.hit_iids,
        "seed": artifact.seed,
        "fuel": artifact.fuel,
        "mutation": artifact.mutation,
        "verdict": VERDICTS[result.outcome],
        "outcome": result.outcome,
        "stage": result.stage,
        "category": error.category if error else "",
        "location": error.location if error else "",
        "message": error.message if error else "",
        "reference_seconds": f"{result.seconds:.2f}",
        "spec_wasm": result.spec_wasm,
        "spec_wasm_message": result.spec_wasm_message,
    }


def git_revision(directory: Path) -> str:
    try:
        head = subprocess.run(
            ["git", "-C", str(directory), "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        dirty = subprocess.run(
            ["git", "-C", str(directory), "status", "--porcelain", "--untracked-files=no"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        return head + (" (dirty)" if dirty else "")
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def table(header: list[str], rows: list[list[str]]) -> list[str]:
    widths = [max(len(str(cell)) for cell in column) for column in zip(header, *rows)]
    def line(cells):
        return "  ".join(str(cell).ljust(width) for cell, width in zip(cells, widths)).rstrip()
    return [line(header)] + [line(row) for row in rows]


def summarize(rows: list[dict], options, conditions: list[str]) -> str:
    sources = ["trapped", "repeat"]
    lines = ["Invocation finding triage", ""] + conditions + [""]
    by_source = Counter(row["source"] for row in rows)
    lines.append(
        f"artifacts: {len(rows)} (trapped {by_source['trapped']}, repeat {by_source['repeat']})"
    )
    lines.append("")
    verdicts = Counter((row["verdict"], row["source"]) for row in rows)
    lines += table(
        ["verdict", *sources, "total"],
        [
            [verdict, *(str(verdicts[(verdict, source)]) for source in sources),
             str(sum(verdicts[(verdict, source)] for source in sources))]
            for verdict in VERDICT_ORDER
        ],
    )
    lines.append("")
    outcomes = Counter((row["outcome"], row["source"]) for row in rows)
    names = sorted(
        {row["outcome"] for row in rows},
        key=lambda name: (VERDICT_ORDER.index(VERDICTS[name]), name),
    )
    lines += table(
        ["outcome", "verdict", *sources, "total"],
        [
            [name, VERDICTS[name], *(str(outcomes[(name, source)]) for source in sources),
             str(sum(outcomes[(name, source)] for source in sources))]
            for name in names
        ],
    )
    if options.spec_check:
        lines.append("")
        checks = Counter((row["spec_wasm"], row["verdict"]) for row in rows)
        lines.append("spec-wasm (trap rules kept) against the reference verdict:")
        lines += table(
            ["spec_wasm", *VERDICT_ORDER],
            [[name, *(str(checks[(name, verdict)]) for verdict in VERDICT_ORDER)]
             for name in sorted({row["spec_wasm"] for row in rows})],
        )
    candidates = [row for row in rows if row["verdict"] == "candidate"]
    lines.append("")
    if not candidates:
        lines.append("candidates: none")
    else:
        groups: dict[tuple[str, str], list[dict]] = defaultdict(list)
        for row in candidates:
            groups[(row["outcome"], row["message"])].append(row)
        lines.append(f"candidates: {len(candidates)} in {len(groups)} distinct (outcome, message) groups")
        for (outcome, message), members in sorted(groups.items(), key=lambda item: (-len(item[1]), item[0])):
            iids = sorted({row["repeat_iid"] or row["intended_iid"] for row in members}, key=lambda v: (len(v), v))
            lines.append(f"  [{len(members)}] {outcome}: {message or '-'}")
            lines.append(f"      iids {' '.join(iids)}")
            for row in members[: options.examples]:
                lines.append(f"      {row['artifact']}")
    return "\n".join(lines) + "\n"


def parse_arguments(argv: list[str] | None = None):
    parser = argparse.ArgumentParser(
        description="Triage invocation-phase findings with the wasm-spectec reference interpreter.",
    )
    parser.add_argument("campaigns", nargs="+", type=Path,
                        help="campaign directories (holding trapped/ and repeat/) or .wast files")
    parser.add_argument("--wasm-spectec", type=Path,
                        default=Path(os.environ.get("WASM_SPECTEC", DEFAULT_WASM_SPECTEC)),
                        help="wasm-spectec checkout whose interpreter/wasm is the reference "
                             "(default: $WASM_SPECTEC or ~/Workspace/wasm-spectec)")
    parser.add_argument("--reference-interpreter", type=Path,
                        help="reference interpreter binary (default: WASM_SPECTEC/interpreter/wasm)")
    parser.add_argument("--out", type=Path,
                        help="output directory (default: CAMPAIGN/triage for one campaign)")
    parser.add_argument("--only", choices=["all", "trapped", "repeat"], default="all",
                        help="which artifacts of a campaign to triage (default: all)")
    parser.add_argument("--jobs", type=int, default=4, help="parallel runs (default: 4)")
    parser.add_argument("--timeout", type=float, default=20.0,
                        help="seconds per reference interpreter run (default: 20)")
    parser.add_argument("--spec-check", action="store_true",
                        help="also run the unmodified spec-wasm with wasm-ntt's P4-SpecTec")
    parser.add_argument("--wasm-ntt", type=Path, default=REPO,
                        help="wasm-ntt checkout for --spec-check (default: this repository)")
    parser.add_argument("--p4spectec", type=Path,
                        help="P4-SpecTec binary for --spec-check (default: WASM_NTT/p4spectec)")
    parser.add_argument("--spec-dir", type=Path,
                        help="specification for --spec-check (default: WASM_NTT/spec-wasm)")
    parser.add_argument("--spec-timeout", type=float, default=60.0,
                        help="seconds per --spec-check run (default: 60)")
    parser.add_argument("--examples", type=int, default=3,
                        help="example artifacts listed per candidate group (default: 3)")
    options = parser.parse_args(argv)
    options.campaigns = [path.resolve() for path in options.campaigns]
    options.wasm_spectec = options.wasm_spectec.expanduser().resolve()
    if options.reference_interpreter is None:
        options.reference_interpreter = options.wasm_spectec / "interpreter" / "wasm"
    options.reference_interpreter = options.reference_interpreter.expanduser().resolve()
    options.wasm_ntt = options.wasm_ntt.expanduser().resolve()
    options.p4spectec = (options.p4spectec or options.wasm_ntt / "p4spectec").expanduser().resolve()
    options.spec_dir = (options.spec_dir or options.wasm_ntt / "spec-wasm").expanduser().resolve()
    if options.out is None:
        directories = [path for path in options.campaigns if path.is_dir()]
        if len(options.campaigns) != 1 or len(directories) != 1:
            parser.error("--out is required unless exactly one campaign directory is given")
        options.out = directories[0] / "triage"
    options.out = options.out.expanduser().resolve()
    if not os.access(options.reference_interpreter, os.X_OK):
        parser.error(
            f"reference interpreter {options.reference_interpreter} is missing; "
            f"build it with `make -C {options.wasm_spectec / 'interpreter'}` "
            "or pass --wasm-spectec/--reference-interpreter"
        )
    if options.spec_check and not os.access(options.p4spectec, os.X_OK):
        parser.error(f"P4-SpecTec binary {options.p4spectec} is missing; pass --p4spectec")
    for path in options.campaigns:
        if not path.exists():
            parser.error(f"{path} does not exist")
    return options


def main(argv: list[str] | None = None) -> int:
    options = parse_arguments(argv)
    artifacts = collect(options.campaigns, options.only)
    if not artifacts:
        print("no artifacts under trapped/ or repeat/", file=sys.stderr)
        return 1
    started = time.monotonic()
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, options.jobs)) as pool:
        futures = [pool.submit(triage, artifact, options) for artifact in artifacts]
        results = []
        for count, future in enumerate(concurrent.futures.as_completed(futures), 1):
            results.append(future.result())
            if count % 50 == 0 or count == len(futures):
                print(f"  {count}/{len(futures)} triaged", file=sys.stderr)
    order = {artifact.path: index for index, artifact in enumerate(artifacts)}
    results.sort(key=lambda result: order[result.artifact.path])
    root = display_root(options.campaigns)
    rows = [row_of(result, root) for result in results]
    options.out.mkdir(parents=True, exist_ok=True)
    with open(options.out / "triage.csv", "w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    conditions = [
        f"date: {datetime.datetime.now().isoformat(timespec='seconds')}",
        f"campaigns: {' '.join(str(path) for path in options.campaigns)}",
        f"reference interpreter: {options.reference_interpreter} "
        f"(wasm-spectec {git_revision(options.wasm_spectec)})",
        f"timeout {options.timeout:g}s, jobs {options.jobs}, only {options.only}, "
        f"wall {time.monotonic() - started:.1f}s",
    ]
    if options.spec_check:
        conditions.append(
            f"spec check: {options.p4spectec} run-wasm {options.spec_dir}/*.watsup "
            f"-rel Scripts_init_ok (wasm-ntt {git_revision(options.wasm_ntt)})"
        )
    summary = summarize(rows, options, conditions)
    (options.out / "summary.txt").write_text(summary)
    (options.out / "conditions.json").write_text(
        json.dumps(
            {
                "campaigns": [str(path) for path in options.campaigns],
                "reference_interpreter": str(options.reference_interpreter),
                "wasm_spectec_revision": git_revision(options.wasm_spectec),
                "timeout": options.timeout,
                "only": options.only,
                "spec_check": options.spec_check,
                "artifacts": len(rows),
            },
            indent=2,
        )
        + "\n"
    )
    print(summary, end="")
    print(f"wrote {options.out / 'triage.csv'} and {options.out / 'summary.txt'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
