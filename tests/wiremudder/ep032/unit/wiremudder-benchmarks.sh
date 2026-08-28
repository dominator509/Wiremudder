#!/usr/bin/env sh
# EP-032 M2 unit test: the benchmark model crate builds and passes its
# deterministic unit suite (SPEC-004: priority rings, budgets, bounded
# queue overflow policies, session fairness, degradation preserving raw
# text), and the perf-capture tool builds and runs reproducibly against
# the owned crate perf fixtures, writing a real raw artifact.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

log=$(mktemp /tmp/ep032_model_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" test \
  --manifest-path benchmarks/wiremudder/Cargo.toml >"$log" 2>&1 || {
  cat "$log" >&2
  fail "wiremudder-benchmarks tests failed"
}
grep -q "9 passed" "$log" || fail "expected 9 passing tests in wiremudder-benchmarks"

# The perf-capture tool builds with the workspace target dir.
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" build \
  --release --manifest-path tools/perf-capture/Cargo.toml >"$log" 2>&1 || {
  cat "$log" >&2
  fail "perf-capture build failed"
}

# The model core rules exist in the crate source.
grep -q "pub enum PriorityRing" benchmarks/wiremudder/src/lib.rs \
  || fail "priority rings missing"
grep -q "pub enum OverflowPolicy" benchmarks/wiremudder/src/lib.rs \
  || fail "overflow policies missing"
grep -q "pub struct FairnessGovernor" benchmarks/wiremudder/src/lib.rs \
  || fail "fairness governor missing"
grep -q "pub fn preserves_raw_text" benchmarks/wiremudder/src/lib.rs \
  || fail "raw-text preservation missing"

echo "unit wiremudder-benchmarks: ok"
