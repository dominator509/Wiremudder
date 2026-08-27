#!/usr/bin/env sh
# Performance test: the boot gate chain (blueprint + preflight + graph
# dispatch + node verifier M1-M3) must complete within a bounded budget.
set -eu
start=$(date +%s%N)
sh scripts/validate-blueprint.sh >/dev/null
sh scripts/preflight.sh >/dev/null
sh scripts/graph-next.sh >/dev/null
sh scripts/node-verifiers/EP-000.sh M1 >/dev/null
sh scripts/node-verifiers/EP-000.sh M2 >/dev/null
sh scripts/node-verifiers/EP-000.sh M3 >/dev/null
end=$(date +%s%N)
ms=$(( (end - start) / 1000000 ))
echo "performance gate-chain: ${ms}ms"
[ "$ms" -lt 60000 ] || { echo "FAIL: gate chain exceeded 60s budget (${ms}ms)" >&2; exit 1; }
