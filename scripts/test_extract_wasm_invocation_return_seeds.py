from __future__ import annotations

import json
import pathlib
import subprocess
import tempfile
import unittest

from scripts import extract_wasm_invocation_return_seeds as return_seeds


REFERENCE = pathlib.Path.home() / "Workspace/wasm-spectec/interpreter/wasm"

# A module with one function of type [] -> [], whose body is the given opcode
# (0x00 unreachable, 0x01 nop) followed by end.
BINARY_TEMPLATE = (
    '(module binary "\\00asm" "\\01\\00\\00\\00" "\\01\\04\\01\\60\\00\\00" '
    '"\\03\\02\\01\\00" "\\0a\\05\\01\\03\\00\\{opcode}\\0b")'
)


class ContainsUnreachableTests(unittest.TestCase):
    def check(self, text: str, expected: bool, interpreter=None) -> None:
        self.assertEqual(return_seeds.contains_unreachable(text, interpreter), expected, text)

    def test_instruction_in_a_text_module(self) -> None:
        self.check('(module (func (export "f") unreachable))', True)
        self.check('(module (func (export "f") (block (unreachable))))', True)

    def test_names_and_comments_are_not_instructions(self) -> None:
        self.check('(module (func (export "unreachable") (nop)))', False)
        self.check('(module (func (export "f") (nop)) ;; unreachable\n)', False)
        self.check('(module (func (export "f") (; unreachable ;) (nop)))', False)

    def test_quoted_module_is_checked_in_its_decoded_text(self) -> None:
        self.check('(module quote "(func (export \\"f\\")" " unreachable)")', True)
        self.check('(module quote "(func (export \\"unreachable\\") (nop))")', False)

    def test_any_module_of_the_seed_counts(self) -> None:
        self.check(
            '(module $M (func (export "g") unreachable)) (register "M" $M) '
            '(module (func (export "f")))',
            True,
        )

    def test_binary_module_without_interpreter_is_refused(self) -> None:
        with self.assertRaises(OSError):
            return_seeds.contains_unreachable(BINARY_TEMPLATE.replace("{opcode}", "01"), None)

    @unittest.skipUnless(REFERENCE.exists(), "reference interpreter not built")
    def test_binary_module_is_printed_by_the_reference_interpreter(self) -> None:
        self.check(BINARY_TEMPLATE.replace("{opcode}", "00"), True, REFERENCE)
        self.check(BINARY_TEMPLATE.replace("{opcode}", "01"), False, REFERENCE)


class GenerateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_context = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.temp_context.name)
        self.source_root = self.root / "core"
        self.source_root.mkdir()
        self.output_dir = self.root / "out"
        # Accepts every seed, like a reference replay that passes.
        self.reference = self.root / "fake-wasm"
        self.reference.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
        self.reference.chmod(0o755)

    def tearDown(self) -> None:
        self.temp_context.cleanup()

    def write(self, name: str, text: str) -> None:
        path = self.source_root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def generate(self) -> dict:
        return return_seeds.generate(
            source_root=self.source_root, output_dir=self.output_dir,
            interpreter=self.reference, timeout_seconds=10.0, jobs=2,
            verify=True, clean=False, limit=None,
        )

    def test_unreachable_seeds_are_excluded_and_recorded(self) -> None:
        self.write("plain.wast",
                   '(module (func (export "f") (result i32) (i32.const 1)))\n'
                   '(assert_return (invoke "f") (i32.const 1))\n')
        self.write("trapping.wast",
                   '(module (func (export "f") (result i32) (i32.const 1))\n'
                   '        (func (export "g") unreachable))\n'
                   '(assert_return (invoke "f") (i32.const 1))\n')
        manifest = self.generate()
        self.assertEqual(sorted(p.name for p in self.output_dir.glob("*.wast")), ["plain_0.wast"])
        statuses = {e["seed"]: e["status"] for e in manifest["entries"]}
        self.assertEqual(statuses, {"plain_0.wast": "accepted",
                                    "trapping_0.wast": "excluded-unreachable"})
        self.assertEqual(manifest["candidate_count"], 2)
        self.assertEqual(manifest["accepted_count"], 1)
        self.assertEqual(manifest["excluded_unreachable_count"], 1)

    def test_long_tests_are_skipped_by_basename(self) -> None:
        self.write("multi-memory/memory_grow.wast",
                   '(module (func (export "f") (result i32) (i32.const 1)))\n'
                   '(assert_return (invoke "f") (i32.const 1))\n')
        manifest = self.generate()
        self.assertEqual(manifest["skipped_long_tests"], ["multi-memory/memory_grow.wast"])
        self.assertEqual(manifest["candidate_count"], 0)

    def test_manifest_records_the_source_commit(self) -> None:
        self.write("plain.wast",
                   '(module (func (export "f") (result i32) (i32.const 1)))\n'
                   '(assert_return (invoke "f") (i32.const 1))\n')
        git = lambda *args: subprocess.run(["git", "-C", str(self.source_root), *args],
                                           check=True, capture_output=True, text=True)
        git("init", "-q")
        git("add", ".")
        git("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "tests")
        head = git("rev-parse", "HEAD").stdout.strip()
        manifest = self.generate()
        self.assertEqual(manifest["source_commit"], head)
        self.assertFalse(manifest["source_dirty"])
        on_disk = json.loads((self.output_dir / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(on_disk["source_commit"], head)

    def test_outside_git_the_commit_is_unknown(self) -> None:
        self.write("plain.wast",
                   '(module (func (export "f") (result i32) (i32.const 1)))\n'
                   '(assert_return (invoke "f") (i32.const 1))\n')
        manifest = self.generate()
        self.assertIsNone(manifest["source_commit"])
        self.assertIsNone(manifest["source_dirty"])


if __name__ == "__main__":
    unittest.main()
