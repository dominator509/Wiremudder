#!/usr/bin/env sh
# Integration test: the real feature-coverage and spec-trace gates pass
# against the live feature catalog and validation matrix (WM-FEAT-0151,
# WM-FEAT-0152).
set -eu
sh scripts/feature-coverage-check.sh >/dev/null 2>&1 || { echo "FAIL: feature coverage gate" >&2; exit 1; }
sh scripts/spec-trace-check.sh >/dev/null 2>&1 || { echo "FAIL: spec trace gate" >&2; exit 1; }
echo "integration traceability-live: ok"
