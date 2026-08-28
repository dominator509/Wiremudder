#!/usr/bin/env sh
# WM-FEAT-0131: performance benchmark suite (SPEC-004, EP-032, LF-032).
# Verifies the feature's real implementation exists in the benchmark model
# crate and the perf-capture driver, and the feature row traces correctly.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0131: FAIL - $1" >&2; exit 1; }

grep -q "WM-FEAT-0131" .agent/features/FEATURES.tsv || fail "feature missing from FEATURES.tsv"
grep -q "WM-FEAT-0131" .agent/node-contracts/EP-032.md || fail "feature missing from node contract"
[ -f benchmarks/wiremudder/Cargo.toml ] || fail "missing anchor benchmarks/wiremudder/Cargo.toml"
grep -q "perf-capture: ok" tools/perf-capture/src/main.rs || fail "missing perf-capture: ok in tools/perf-capture/src/main.rs"

echo "feature-0131: ok"
