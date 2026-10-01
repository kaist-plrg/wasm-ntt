#!/bin/sh

set -eu

binary=${1:-./p4spectec}
repo_root=$(git rev-parse --show-toplevel)
test_root="$repo_root/p4spec/test/wasm-invoke-arguments"
output_root=$(mktemp -d "${TMPDIR:-/tmp}/wasm-invoke-arguments.XXXXXX")
trap 'rm -rf "$output_root"' EXIT HUP INT TERM

run_script() {
  mode=$1
  file=$2
  output=$3
  "$binary" run-wasm "$repo_root"/spec-wasm/*.watsup \
    -rel Scripts_init_ok \
    -w "$test_root/$file" \
    "-$mode" \
    >"$output" 2>&1 || true
}

require_line() {
  output=$1
  line=$2
  grep -Fxq "$line" "$output" || {
    echo "expected \"$line\" in:" >&2
    cat "$output" >&2
    exit 1
  }
}

# The harness checks invoke arguments against the function type like the
# reference interpreter's script runner, before the Invoke relation runs
for mode in il sl; do
  output="$output_root/$mode-matching.out"
  run_script "$mode" matching.wast "$output"
  require_line "$output" "Passed"

  for file in too-few.wast too-many.wast trap-assertion.wast; do
    output="$output_root/$mode-${file%.wast}.out"
    run_script "$mode" "$file" "$output"
    require_line "$output" "Failed (runtime error): wrong number of arguments"
  done

  for file in number-type.wast reference-type.wast null-to-non-null.wast; do
    output="$output_root/$mode-${file%.wast}.out"
    run_script "$mode" "$file" "$output"
    require_line "$output" "Failed (runtime error): wrong type of argument"
  done
done
