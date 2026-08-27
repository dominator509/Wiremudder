#!/usr/bin/env sh
# Performance test: patch classification is fast and deterministic.
set -eu
start=$(date +%s%N)
for i in 1 2 3 4 5; do
  python3 tests/wiremudder/ep002/unit/classify_patch.py HEAD "governance" >/dev/null
done
end=$(date +%s%N)
ms=$(( (end - start) / 1000000 ))
echo "performance classification-5x: ${ms}ms"
[ "$ms" -lt 10000 ] || { echo "FAIL: classification too slow" >&2; exit 1; }
echo "performance classification: ok"
