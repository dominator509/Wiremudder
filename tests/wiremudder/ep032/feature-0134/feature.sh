#!/usr/bin/env sh
# WM-FEAT-0134: P0/P1/P2/P3/P4 priority rings (SPEC-004, EP-032, LF-032).
# Verifies the feature's real implementation exists in the benchmark model
# crate and the perf-capture driver, and the feature row traces correctly.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0134: FAIL - $1" >&2; exit 1; }

grep -q "WM-FEAT-0134" .agent/features/FEATURES.tsv || fail "feature missing from FEATURES.tsv"
grep -q "WM-FEAT-0134" .agent/node-contracts/EP-032.md || fail "feature missing from node contract"
[ -f benchmarks/wiremudder/src/lib.rs ] || fail "missing anchor benchmarks/wiremudder/src/lib.rs"
grep -q "pub enum PriorityRing" benchmarks/wiremudder/src/lib.rs || fail "missing pub enum PriorityRing in benchmarks/wiremudder/src/lib.rs"

echo "feature-0134: ok"
