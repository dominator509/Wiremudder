#!/usr/bin/env sh
# EP-024 M4 performance test: real measured voice paths against the
# SPEC-004 budget. Fails unless the perf fixture is green, raw
# distributions are recorded, and emergency stop stays under the P0
# 10 ms budget while all P3 paths stay under the 5 ms budget.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-voice/Cargo.toml \
  --example perf_fixture 2>&1 | tee /tmp/ep024_perf.log

grep -q "perf fixture EP-024: ok" /tmp/ep024_perf.log || fail "perf fixture not green"
grep -q "perf recognize-propose" /tmp/ep024_perf.log || fail "recognize path missing"
grep -q "perf enqueue-speech" /tmp/ep024_perf.log || fail "enqueue path missing"
grep -q "perf barge-in-sweep" /tmp/ep024_perf.log || fail "barge-in path missing"
grep -q "perf snapshot" /tmp/ep024_perf.log || fail "snapshot path missing"
grep -q "perf remote-policy-check" /tmp/ep024_perf.log || fail "remote policy path missing"
grep -q "perf emergency-stop" /tmp/ep024_perf.log || fail "emergency stop path missing"
grep -q "budget_ms=5" /tmp/ep024_perf.log || fail "P3 budget not recorded"
grep -q "budget_ms=10 (P0)" /tmp/ep024_perf.log || fail "P0 emergency-stop budget not recorded"

echo "performance EP-024 M4 fixture: ok"
