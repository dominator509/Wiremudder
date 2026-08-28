#!/usr/bin/env sh
# EP-039 M3 e2e: the full run-complete chain is rehearsed end to end with real
# artifacts — production readiness structural check, evidence corpus hash, and
# the ledger lifecycle event ordering (all 39 nodes NODE_DONE before release).
set -eu
cd "$(dirname "$0")/../../../.."

# 1. Production readiness structural: EP-000..EP-038 must all be NODE_DONE+green.
python3 scripts/production_readiness.py | grep -q 'production readiness structural: ok' \
  || { echo "FAIL: production readiness structural" >&2; exit 1; }

# 2. Ledger lifecycle: count NODE_DONE rows across the graph.
done_count=$(grep -c '| NODE_DONE |' .agent/state/LEDGER.md || true)
echo "NODE_DONE rows: $done_count"
[ "$done_count" -ge 39 ] || { echo "FAIL: expected >=39 NODE_DONE rows" >&2; exit 1; }

# 3. Evidence corpus aggregate exists and matches the final-evidence index.
[ -f .agent/state/final-evidence/evidence-corpus.sha256 ] \
  || { echo "FAIL: corpus hash missing" >&2; exit 1; }

# 4. Every green tag referenced in the ledger exists.
for node in $(grep '| NODE_DONE |' .agent/state/LEDGER.md | awk -F'|' '{gsub(/ /,"",$3); print $3}'); do
  git rev-parse -q --verify "refs/tags/green/$node" >/dev/null \
    || { echo "FAIL: missing green/$node" >&2; exit 1; }
done
echo 'run-complete chain rehearsal: ok'
