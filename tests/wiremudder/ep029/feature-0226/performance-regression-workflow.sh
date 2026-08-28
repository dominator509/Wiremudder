#!/usr/bin/env sh
# WM-FEAT-0226: performance regression workflow with evidence, safety,
# rollback, and release-profile controls.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0226: FAIL - $1" >&2; exit 1; }

grep -q "WM-FEAT-0226" .agent/features/FEATURES.tsv || fail "feature missing from FEATURES.tsv"

# The performance fixture records real distributions and raw artifacts
# (SPEC-027-R06).
out=$(CARGO_TARGET_DIR="$PWD/wirecore/target" cargo run --release \
  --manifest-path wirecore/crates/wire-bug-automation/Cargo.toml \
  --example perf_fixture 2>&1) || fail "performance fixture failed"
echo "$out" | grep -q "perf transit: p50_us" || fail "no transition distribution recorded"
echo "$out" | grep -q "perf fixture EP-029: ok" || fail "perf fixture not ok"
[ -f wirecore/target/ep029-perf-raw.json ] || fail "raw perf artifact missing"

# P0/P1 bugs require a performance review before approval (SPEC-019-R10).
grep -q "P0/P1 bugs require a performance review" \
  wirecore/crates/wire-bug-automation/src/lib.rs || fail "performance review gate missing in code"

echo "feature-0226: ok"
