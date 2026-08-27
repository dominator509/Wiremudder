#!/usr/bin/env sh
# Failure test: patch classification must fail closed on an unknown
# range (no crash, no guess).
set -eu
set +e
out=$(python3 tests/wiremudder/ep002/unit/classify_patch.py "not-a-real-rev" "probe" 2>/dev/null)
rc=$?
set -e
[ "$rc" -eq 0 ] || { echo "FAIL: classifier crashed on unknown range" >&2; exit 1; }
[ "$out" = "unclassified" ] || { echo "FAIL: expected unclassified, got $out" >&2; exit 1; }
echo "failure classifier-fail-closed: ok"
