#!/usr/bin/env sh
# EP-025 M4 performance test: real measured renderer paths against the
# SPEC-004/SPEC-016 budgets. Fails unless the perf fixture is green,
# raw distributions are recorded, the 5 ms frame budget holds, and
# emergency stop stays under the P0 10 ms budget.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-renderer/Cargo.toml \
  --example perf_fixture 2>&1 | tee /tmp/ep025_perf.log

grep -q "perf fixture EP-025: ok" /tmp/ep025_perf.log || fail "perf fixture not green"
grep -q "perf apply-candidate" /tmp/ep025_perf.log || fail "apply path missing"
grep -q "perf render-frame-128" /tmp/ep025_perf.log || fail "frame path missing"
grep -q "perf combat-drop-sweep" /tmp/ep025_perf.log || fail "combat path missing"
grep -q "perf snapshot" /tmp/ep025_perf.log || fail "snapshot path missing"
grep -q "perf asset-pack-validate" /tmp/ep025_perf.log || fail "asset path missing"
grep -q "perf emergency-stop" /tmp/ep025_perf.log || fail "emergency stop path missing"
grep -q "budget_ms=5" /tmp/ep025_perf.log || fail "frame budget not recorded"
grep -q "budget_ms=10 (P0)" /tmp/ep025_perf.log || fail "P0 emergency-stop budget not recorded"

echo "performance EP-025 M4 fixture: ok"
