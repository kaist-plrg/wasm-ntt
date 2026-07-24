#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -x "./p4spectec" ]]; then
  echo "Error: ./p4spectec not found or not executable in $ROOT_DIR"
  exit 1
fi

COMMON_ARGS=(
  wasm-testgen
  spec-wasm/*.watsup
  -rel "Modules_ok"
  -fuel 100
  -gen-dir gen-wasm
  -seed 20254289
  -boot-dir test-pos
)

launch_mode() {
  local mode="$1"
  local campaign_name="$2"
  local logfile="$3"
  local pidfile="$4"
  shift 4

  if [[ -f "$pidfile" ]]; then
    local old_pid
    old_pid="$(cat "$pidfile" 2>/dev/null || true)"
    if [[ -n "${old_pid}" ]] && kill -0 "${old_pid}" 2>/dev/null; then
      echo "Skip ${mode}: already running (pid=${old_pid}, pidfile=${pidfile})"
      return 0
    fi
  fi

  echo "Starting ${mode}..."
  nohup ./p4spectec "${COMMON_ARGS[@]}" -name "${campaign_name}" "$@" \
    > "${logfile}" 2>&1 < /dev/null &
  local pid=$!
  echo "${pid}" > "${pidfile}"
  echo "Started ${mode}: pid=${pid}, log=${logfile}, pidfile=${pidfile}"

  if wait "${pid}"; then
    echo "Completed ${mode}: pid=${pid}"
  else
    local status=$?
    echo "Failed ${mode}: pid=${pid}, exit=${status}, log=${logfile}"
    return "${status}"
  fi
}

launch_mode "random" "C1-random" "gen-wasm-random.txt" "gen-wasm-random.pid" "-random"
launch_mode "hybrid" "C1-hybrid" "gen-wasm-hybrid.txt" "gen-wasm-hybrid.pid" "-hybrid"
launch_mode "derive" "C1-derive" "gen-wasm-derive.txt" "gen-wasm-derive.pid"

cat <<'EOF'

Monitor:
  tail -f gen-wasm-random.txt gen-wasm-hybrid.txt gen-wasm-derive.txt

Run this whole script in background:
  nohup ./scripts/run_wasm_testgen_modes.sh > run_wasm_testgen_modes.log 2>&1 < /dev/null &
EOF
