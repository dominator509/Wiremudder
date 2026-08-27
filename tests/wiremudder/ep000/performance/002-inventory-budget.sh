#!/usr/bin/env sh
# Performance test: upstream-tree inventory generation must complete
# within a bounded budget and remain deterministic in path count.
set -eu
start=$(date +%s%N)
python3 tests/wiremudder/ep000/unit/gen_upstream_tree.py >/dev/null
end=$(date +%s%N)
ms=$(( (end - start) / 1000000 ))
count=$(wc -l < .agent/state/upstream-tree.tsv)
echo "performance inventory: ${ms}ms paths=$((count - 1))"
[ "$ms" -lt 60000 ] || { echo "FAIL: inventory exceeded 60s budget (${ms}ms)" >&2; exit 1; }
[ "$((count - 1))" -gt 1000 ] || { echo "FAIL: inventory path count implausible" >&2; exit 1; }
