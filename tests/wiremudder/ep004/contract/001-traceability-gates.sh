#!/usr/bin/env sh
# Contract test: traceability gates exist and are wired to real state
# (feature coverage, spec trace, expected-file audit).
set -eu
[ -f scripts/feature-coverage-check.sh ] || { echo "FAIL: feature coverage gate missing" >&2; exit 1; }
[ -f scripts/spec-trace-check.sh ] || { echo "FAIL: spec trace gate missing" >&2; exit 1; }
[ -f scripts/expected-files-audit.sh ] || { echo "FAIL: expected-file audit missing" >&2; exit 1; }
[ -f .agent/features/FEATURES.tsv ] || { echo "FAIL: feature catalog missing" >&2; exit 1; }
[ -f .agent/requirements/VALIDATION_MATRIX.tsv ] || { echo "FAIL: validation matrix missing" >&2; exit 1; }
n=$(grep -c "WM-FEAT" .agent/features/FEATURES.tsv)
[ "$n" -ge 200 ] || { echo "FAIL: feature count $n < 200" >&2; exit 1; }
echo "contract traceability-gates: ok features=$n"
