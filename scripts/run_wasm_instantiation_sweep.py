#!/usr/bin/env python3
"""Run the Wasm instantiation harness over a directory of .wast files."""

from __future__ import annotations

import argparse
import concurrent.futures
import csv
import datetime as dt
import pathlib
import subprocess
import sys
import time
from collections import Counter


def positive_int(value: str) -> int:
    parsed = int(value)
    if parsed < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return parsed


def classify(stdout: str, stderr: str, timed_out: bool, returncode: int) -> tuple[str, str]:
    text = stdout + "\n" + stderr
    lowered = text.lower()
    if timed_out:
        return ("timeout", "per-file timeout")
    if "unknown import module spectest" in text:
        return ("failed", "spectest import resolution failed")
    if "unsupported wasm script command" in text:
        return ("excluded", "script command is not implemented")
    if "expected validation failure" in text:
        return ("failed", "invalid module was accepted")
    if "expected linking failure" in text:
        return ("failed", "unlinkable module was accepted")
    if "expected instantiation failure" in text:
        return ("failed", "uninstantiable module was accepted")
    if "failed (syntax error)" in lowered or "failed to parse" in lowered:
        return ("excluded", "parser does not accept this test input")
    if "failed (runtime error)" in lowered:
        return ("failed", "runtime/spec failure")
    if "passed" in lowered and returncode == 0:
        return ("passed", "")
    if returncode != 0:
        return ("failed", f"process exited with {returncode}")
    return ("failed", "unknown result")


def tail(text: str, limit: int = 1200) -> str:
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[-limit:]


def read_source(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def run_one(
    cmd: list[str], timeout_s: float | None
) -> tuple[int, str, str, bool, float]:
    started_at = time.monotonic()
    try:
        completed = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout_s,
        )
        elapsed_s = time.monotonic() - started_at
        return (
            completed.returncode,
            completed.stdout,
            completed.stderr,
            False,
            elapsed_s,
        )
    except subprocess.TimeoutExpired as exc:
        elapsed_s = time.monotonic() - started_at
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode(errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode(errors="replace")
        return (124, stdout, stderr, True, elapsed_s)


def run_indexed(
    index: int,
    path: pathlib.Path,
    p4spectec: str,
    spec: list[str],
    relation: str,
    mode: str,
    wasm_script_debug: bool,
    timeout_s: float | None,
) -> dict[str, str]:
    cmd = [
        p4spectec,
        "run-wasm",
        *spec,
        "-rel",
        relation,
        "-w",
        str(path),
        f"-{mode}",
    ]
    if wasm_script_debug:
        cmd.append("-wasm-script-debug")
    returncode, stdout, stderr, timed_out, elapsed_s = run_one(cmd, timeout_s)
    status, reason = classify(stdout, stderr, timed_out, returncode)
    source = read_source(path)
    return {
        "index": str(index),
        "file": str(path),
        "status": status,
        "reason": reason,
        "elapsed_seconds": f"{elapsed_s:.3f}",
        "returncode": str(returncode),
        "has_spectest": str('"spectest"' in source).lower(),
        "has_start": str("(start" in source).lower(),
        "has_assert_unlinkable": str("assert_unlinkable" in source).lower(),
        "has_assert_uninstantiable": str(
            "assert_uninstantiable" in source
        ).lower(),
        "has_invoke_or_action": str(
            "(invoke" in source or "assert_return" in source
        ).lower(),
        "tail": tail(stdout + stderr),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="test", help="directory containing .wast files")
    parser.add_argument(
        "--file",
        action="append",
        dest="files",
        help="run one explicit .wast file; repeat to select multiple files",
    )
    parser.add_argument("--p4spectec", default="./p4spectec")
    parser.add_argument("--spec", nargs="+", default=None)
    parser.add_argument("--rel", default="Scripts_init_ok")
    parser.add_argument("--mode", choices=["il", "sl"], default="il")
    timeout_group = parser.add_mutually_exclusive_group()
    timeout_group.add_argument("--timeout", type=float, default=None)
    timeout_group.add_argument(
        "--no-timeout",
        action="store_true",
        help="disable the per-file timeout; requires at least one --file",
    )
    parser.add_argument(
        "--jobs",
        type=positive_int,
        default=1,
        help="maximum concurrent files; defaults to sequential execution",
    )
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument(
        "--wasm-script-debug",
        action="store_true",
        help="pass -wasm-script-debug to p4spectec run-wasm",
    )
    parser.add_argument("--out-dir", default="result-analysis/wasm-instantiation-sweep")
    args = parser.parse_args()

    if args.no_timeout and not args.files:
        parser.error("--no-timeout requires at least one --file")
    if args.no_timeout:
        timeout_s = None
    elif args.timeout is not None:
        timeout_s = args.timeout
    else:
        timeout_s = 30.0

    root = pathlib.Path(args.root)
    files = (
        [pathlib.Path(path) for path in args.files]
        if args.files
        else sorted(root.rglob("*.wast"))
    )
    if args.limit is not None:
        files = files[: args.limit]

    spec = args.spec or sorted(str(path) for path in pathlib.Path("spec-wasm").glob("*.watsup"))
    out_dir = pathlib.Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    rows: list[dict[str, str]] = []
    counts: Counter[str] = Counter()
    reason_counts: Counter[str] = Counter()

    indexed_files = list(enumerate(files, start=1))

    def execute(index: int, path: pathlib.Path) -> dict[str, str]:
        return run_indexed(
            index,
            path,
            args.p4spectec,
            spec,
            args.rel,
            args.mode,
            args.wasm_script_debug,
            timeout_s,
        )

    if args.jobs == 1:
        for index, path in indexed_files:
            row = execute(index, path)
            rows.append(row)
            print(
                f"[{index}/{len(files)}] {row['status']:8} {path} {row['reason']}",
                flush=True,
            )
    else:
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=args.jobs
        ) as executor:
            futures = [
                executor.submit(execute, index, path)
                for index, path in indexed_files
            ]
            for future in concurrent.futures.as_completed(futures):
                row = future.result()
                rows.append(row)
                print(
                    f"[{row['index']}/{len(files)}] "
                    f"{row['status']:8} {row['file']} {row['reason']}",
                    flush=True,
                )
        rows.sort(key=lambda row: int(row["index"]))

    for row in rows:
        status = row["status"]
        reason = row["reason"]
        counts[status] += 1
        if reason:
            reason_counts[reason] += 1

    csv_path = out_dir / "results.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()) if rows else [])
        writer.writeheader()
        writer.writerows(rows)

    md_path = out_dir / "summary.md"
    now = dt.datetime.now().isoformat(timespec="seconds")
    with md_path.open("w", encoding="utf-8") as handle:
        handle.write("# Wasm Instantiation Sweep Summary\n\n")
        handle.write(f"- generated_at: `{now}`\n")
        handle.write(f"- root: `{root}`\n")
        handle.write(f"- files: `{len(files)}`\n")
        handle.write(f"- mode: `{args.mode}`\n")
        handle.write(f"- relation: `{args.rel}`\n")
        timeout_label = "none" if timeout_s is None else str(timeout_s)
        handle.write(f"- timeout_seconds: `{timeout_label}`\n")
        handle.write(f"- jobs: `{args.jobs}`\n\n")
        handle.write("## Status Counts\n\n")
        for status, count in sorted(counts.items()):
            handle.write(f"- `{status}`: {count}\n")
        handle.write("\n## Reason Counts\n\n")
        for reason, count in reason_counts.most_common():
            handle.write(f"- `{reason}`: {count}\n")
        handle.write("\n## Failed Or Excluded Files\n\n")
        for row in rows:
            if row["status"] != "passed":
                handle.write(f"- `{row['status']}` `{row['file']}`: {row['reason']}\n")

    print(f"\nWrote {csv_path}")
    print(f"Wrote {md_path}")
    return 0 if counts.get("failed", 0) == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
