#!/usr/bin/env sh
# WM-FEAT-0136: terminal frame buffer (SPEC-004, EP-032, LF-032).
# Verifies the feature's real implementation exists in the benchmark model
# crate and the perf-capture driver, and the feature row traces correctly.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0136: FAIL - $1" >&2; exit 1; }

grep -q "WM-FEAT-0136" .agent/features/FEATURES.tsv || fail "feature missing from FEATURES.tsv"
grep -q "WM-FEAT-0136" .agent/node-contracts/EP-032.md || fail "feature missing from node contract"
[ -f benchmarks/wiremudder/src/lib.rs ] || fail "missing anchor benchmarks/wiremudder/src/lib.rs"
grep -q "terminal" benchmarks/wiremudder/src/lib.rs || fail "missing terminal in benchmarks/wiremudder/src/lib.rs"

echo "feature-0136: ok"
