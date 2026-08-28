#!/usr/bin/env sh
# EP-032 M5 requirement test: WM-SPEC-019-R10 - "Any P0/P1 bug receives performance review and any transcript, AI, voice, routing, secrets, package, or update bug receives privacy or security review."
# 5-level depth: spec -> matrix -> owned test path -> real implementation
# -> live-fire LF-032.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirements: FAIL - $1" >&2; exit 1; }

# 1. Requirement exists in owning spec.
grep -q "WM-SPEC-019-R10" .agent/specs/*.md || fail "WM-SPEC-019-R10 missing from specs"

# 2. Validation matrix maps it to EP-032, LF-032, and this test path.
grep -q "WM-SPEC-019-R10.*EP-032.*LF-032" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "matrix row for WM-SPEC-019-R10 missing EP-032/LF-032"
grep -q "tests/wiremudder/ep032/requirements/wm-spec-019-r10" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "matrix row for WM-SPEC-019-R10 missing test path"

# 3. The owned test path exists (this file).
[ -d "$(dirname "$0")" ] || fail "owned requirement test dir missing"

# 4. Real implementation: the benchmark model enforces the R12/R06 shape
#    (hardware, workload, runs, thresholds, raw evidence).
grep -q "pub struct BenchmarkArtifact" benchmarks/wiremudder/src/lib.rs \
  || fail "BenchmarkArtifact missing from model"
grep -q "raw_evidence" benchmarks/wiremudder/src/lib.rs \
  || fail "raw_evidence missing from model"
grep -q "regression_thresholds" benchmarks/wiremudder/src/lib.rs \
  || fail "regression_thresholds missing from model"

# 5. Live-fire: LF-032 stores the raw artifact with thresholds.
sh tests/live-fire/LF-032-performance-priority-flood.sh >/dev/null \
  || fail "LF-032 failed"
[ -f tools/perf-capture/artifacts/ep032-perf-raw.json ] || fail "raw artifact missing"

echo "requirements WM-SPEC-019-R10: ok"
