#!/usr/bin/env sh
# EP-029 M4 performance test: the real performance fixture runs through the
# production wire-bug-automation crate in release mode and stays within the
# SPEC-004 budget (5 ms). Raw evidence is written by the fixture.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep029_perf_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --release \
  --manifest-path wirecore/crates/wire-bug-automation/Cargo.toml \
  --example perf_fixture >"$out" 2>&1 || {
  cat "$out" >&2
  fail "performance fixture did not run"
}

grep -q "perf redact:" "$out" || fail "redaction measurement missing"
grep -q "perf transit:" "$out" || fail "transition measurement missing"
grep -q "perf route:" "$out" || fail "routing measurement missing"
grep -q "budget_us=5000" "$out" || fail "budget line missing"
grep -q "perf fixture EP-029: ok" "$out" || fail "perf fixture not ok"
[ -f wirecore/target/ep029-perf-raw.json ] || fail "raw perf artifact missing"

echo "performance EP-029 fixture: ok"
