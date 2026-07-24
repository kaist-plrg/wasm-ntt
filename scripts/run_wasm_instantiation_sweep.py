#!/usr/bin/env python3
"""Run the Wasm instantiation harness over a directory of .wast files."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import pathlib
import subprocess
import sys
from collections import Counter


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
    if "passed" in lowered:
        return ("passed", "")
    if returncode != 0:
        return ("failed", f"process exited with {returncode}")
    return ("failed", "unknown result")


def tail(text: str, limit: int = 1200) -> str:
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[-limit:]


def has_token(path: pathlib.Path, token: str) -> bool:
    try:
        return token in path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return False


def run_one(cmd: list[str], timeout_s: float) -> tuple[int, str, str, bool]:
    try:
        completed = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout_s,
        )
        return (completed.returncode, completed.stdout, completed.stderr, False)
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode(errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode(errors="replace")
        return (124, stdout, stderr, True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="test", help="directory containing .wast files")
    parser.add_argument("--p4spectec", default="./p4spectec")
    parser.add_argument("--spec", nargs="+", default=None)
    parser.add_argument("--rel", default="Scripts_init_ok")
    parser.add_argument("--mode", choices=["il", "sl"], default="il")
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument(
        "--wasm-script-debug",
        action="store_true",
        help="pass -wasm-script-debug to p4spectec run-wasm",
    )
    parser.add_argument("--out-dir", default="result-analysis/wasm-instantiation-sweep")
    args = parser.parse_args()

    root = pathlib.Path(args.root)
    files = sorted(root.rglob("*.wast"))
    if args.limit is not None:
        files = files[: args.limit]

    spec = args.spec or sorted(str(path) for path in pathlib.Path("spec-wasm").glob("*.watsup"))
    out_dir = pathlib.Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    rows: list[dict[str, str]] = []
    counts: Counter[str] = Counter()
    reason_counts: Counter[str] = Counter()

    for index, path in enumerate(files, start=1):
        cmd = [
            args.p4spectec,
            "run-wasm",
            *spec,
            "-rel",
            args.rel,
            "-w",
            str(path),
            f"-{args.mode}",
        ]
        if args.wasm_script_debug:
            cmd.append("-wasm-script-debug")
        returncode, stdout, stderr, timed_out = run_one(cmd, args.timeout)
        status, reason = classify(stdout, stderr, timed_out, returncode)
        counts[status] += 1
        if reason:
            reason_counts[reason] += 1
        row = {
            "index": str(index),
            "file": str(path),
            "status": status,
            "reason": reason,
            "returncode": str(returncode),
            "has_spectest": str(has_token(path, '"spectest"')).lower(),
            "has_start": str(has_token(path, "(start")).lower(),
            "has_assert_unlinkable": str(has_token(path, "assert_unlinkable")).lower(),
            "has_assert_uninstantiable": str(has_token(path, "assert_uninstantiable")).lower(),
            "has_invoke_or_action": str(
                has_token(path, "(invoke") or has_token(path, "assert_return")
            ).lower(),
            "tail": tail(stdout + stderr),
        }
        rows.append(row)
        print(f"[{index}/{len(files)}] {status:8} {path} {reason}", flush=True)

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
        handle.write(f"- timeout_seconds: `{args.timeout}`\n\n")
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
