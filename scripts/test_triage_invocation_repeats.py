from __future__ import annotations

import contextlib
import csv
import io
import pathlib
import tempfile
import unittest

from scripts import triage_invocation_repeats as triage


REFERENCE = pathlib.Path.home() / "Workspace/wasm-spectec/interpreter/wasm"

HEADER = ";; Intended iid 2509\n;; Source vid 1\n\n;; Mutation GenFromTyp\n\n(;\nFrom [ (x) ]\nTo [ (y) ]\n;)\n\n"
FINAL = '\n(assert_trap (invoke "f") "")\n\n;; Covered iids { 2509 }\n'

# Each script is a rendered invocation artifact: a prefix, the target module,
# replayed commands, and the stuck invocation asserted as a trap.
CASES = {
    "reference-trap": '(module (func (export "f") unreachable))',
    "reference-no-trap": '(module (func (export "f") (result i32) (i32.const 1)))',
    "reference-invalid": (
        '(module (memory $m0 i64 1) (memory $m1 1)\n'
        '  (func (export "f") (result i32)\n'
        '    (i32.const 0) (i32.load $m1 offset=4294967296)))'
    ),
    "prefix-invalid": (
        '(module (func (result i32) (i64.const 0)))\n(module (func (export "f") unreachable))'
    ),
    "reference-instantiation-trap": (
        '(module (memory 1) (data (i32.const 65536) "a") (func (export "f") unreachable))'
    ),
    "reference-link-failure": (
        '(module (import "spectest" "no_such_export" (func)) (func (export "f") unreachable))'
    ),
    "reference-exception": '(module (tag $t) (func (export "f") (throw $t)))',
    "reference-exhaustion": '(module (func $f (export "f") (call $f)))',
    "reference-script-error": '(module (func (export "f") (param i32) unreachable))',
    "replay-failure": (
        '(module (func (export "g") unreachable) (func (export "f") unreachable))\n(invoke "g")'
    ),
    "reference-parse-error": '(module (func (export "f") (i32.bogus)))',
    "reference-timeout": '(module (func (export "f") (loop (br 0))))',
}


class FormTests(unittest.TestCase):
    def test_comments_and_strings_do_not_open_forms(self) -> None:
        text = (
            ';; (module\n(; nested (; (module) ;) ;)\n'
            '(module $m\n  (data "(;" ")")\n)\n'
            '(module instance $i $m)\n(assert_trap (invoke "f") "")\n'
        )
        forms = triage.top_level_forms(text)
        self.assertEqual(
            [(form.head, form.first_line, form.last_line, form.second) for form in forms],
            [("module", 3, 5, "$m"), ("module", 6, 6, "instance"), ("assert_trap", 7, 7, "")],
        )
        layout = triage.Layout.of_text(text)
        self.assertEqual((layout.modules, layout.assertions), (1, 1))
        self.assertEqual(layout.target.first_line, 6)
        self.assertEqual(layout.region(7), "final")
        self.assertEqual(layout.region(6), "target")
        self.assertEqual(layout.region(1), "prefix")

    def test_unmatched_close_does_not_hide_later_forms(self) -> None:
        forms = triage.top_level_forms(')\n(module)\n(assert_trap (invoke "f") "")\n')
        self.assertEqual([form.head for form in forms], ["module", "assert_trap"])

    def test_header_block_comment_is_skipped(self) -> None:
        layout = triage.Layout.of_text(HEADER + CASES["reference-trap"] + FINAL)
        self.assertEqual((layout.modules, layout.assertions), (1, 1))
        self.assertEqual(layout.final.head, "assert_trap")


class OutputParsingTests(unittest.TestCase):
    def test_located_and_fatal_errors(self) -> None:
        artifact = pathlib.Path("/tmp/a.wast")
        error = triage.parse_reference_error(
            "/tmp/a.wast:12.3-12.40: validation error: type mismatch: expected i32\n", artifact
        )
        self.assertEqual(
            (error.category, error.message, error.line, error.location),
            ("validation error", "type mismatch: expected i32", 12, "12.3-12.40"),
        )
        error = triage.parse_reference_error(
            "/opt/wasm/interpreter/wasm: uncaught exception Out_of_memory\n", artifact
        )
        self.assertEqual((error.category, error.message), ("fatal", "Out_of_memory"))

    def test_trace_attributes_the_invocation_to_its_assertion(self) -> None:
        artifact = pathlib.Path("/tmp/a.wast")
        trace = "\n".join(
            [
                '-- Running ("(input \\"/tmp/a.wast\\")")...',
                "-- Loading (/tmp/a.wast)...",
                "-- Checking...",
                "-- Initializing...",
                '-- Invoking function "g"...',
                "-- Asserting trap...",
                '-- Invoking function "f"...',
                "-- Error: ",
            ]
        )
        stage = triage.last_stage(trace, artifact)
        self.assertEqual((stage.kind, stage.checked, stage.asserted), ("assert", 1, 1))
        stage = triage.last_stage("\n".join(trace.splitlines()[:5]), artifact)
        self.assertEqual(stage.kind, "action")


@unittest.skipUnless(REFERENCE.exists(), "needs the wasm-spectec reference interpreter")
class ReferenceTriageTests(unittest.TestCase):
    def test_outcomes_of_synthetic_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            campaign = pathlib.Path(directory) / "campaign"
            (campaign / "trapped").mkdir(parents=True)
            (campaign / "repeat" / "2509").mkdir(parents=True)
            for outcome, body in CASES.items():
                name = outcome.replace("-", "_") + "_F2P2509S0D1M3T4.wast"
                (campaign / "trapped" / name).write_text(HEADER + body + FINAL)
            (campaign / "repeat" / "2509" / "repeat_F1P2509S0D0M0T1.wast").write_text(
                HEADER + CASES["reference-trap"] + FINAL.replace("Covered", "Repeat hit")
            )
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                status = triage.main(
                    [str(campaign), "--wasm-spectec", str(REFERENCE.parent.parent), "--timeout", "3"]
                )
            self.assertEqual(status, 0)
            with open(campaign / "triage" / "triage.csv") as handle:
                rows = list(csv.DictReader(handle))
            outcomes = {
                row["artifact"].split("/")[-1].split("_F2P")[0].replace("_", "-"): row
                for row in rows
                if row["source"] == "trapped"
            }
            for outcome in CASES:
                with self.subTest(outcome=outcome):
                    self.assertEqual(outcomes[outcome]["outcome"], outcome)
                    self.assertEqual(outcomes[outcome]["verdict"], triage.VERDICTS[outcome])
                    self.assertEqual(outcomes[outcome]["intended_iid"], "2509")
                    self.assertEqual(outcomes[outcome]["fuel"], "2")
            repeat = [row for row in rows if row["source"] == "repeat"]
            self.assertEqual(len(repeat), 1)
            self.assertEqual(
                (repeat[0]["repeat_iid"], repeat[0]["hit_iids"], repeat[0]["outcome"]),
                ("2509", "2509", "reference-trap"),
            )
            self.assertTrue((campaign / "triage" / "summary.txt").exists())


if __name__ == "__main__":
    unittest.main()
