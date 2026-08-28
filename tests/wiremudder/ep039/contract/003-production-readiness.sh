#!/usr/bin/env sh
# EP-039 M1 contract: production readiness requires every node EP-000..EP-038
# to be DONE (NODE_DONE ledger row + green tag) and the ship-gate artifacts
# present; the readiness check must pass with real state.
set -eu

fail() { echo "ep039 contract: FAIL - $1" >&2; exit 1; }

python3 scripts/production_readiness.py >/dev/null 2>&1 \
  || fail "production readiness structural check failed"

# All 39 prior nodes must carry a NODE_DONE ledger row and green tag.
for i in $(seq -w 0 38); do
  grep -q "| EP-0$i | NODE_DONE |" .agent/state/LEDGER.md \
    || fail "EP-0$i missing NODE_DONE"
  git rev-parse -q --verify "refs/tags/green/EP-0$i" >/dev/null \
    || fail "green/EP-0$i tag missing"
done

echo "ep039 contract production-readiness: ok"
