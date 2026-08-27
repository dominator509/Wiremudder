#!/usr/bin/env sh
set -eu
[ -f .env ] && { set -a; . ./.env; set +a; }
agent=${WIREMUDDER_AGENT_ID:-}
[ -n "$agent" ] || { echo 'lease: WIREMUDDER_AGENT_ID is required' >&2; exit 1; }
cmd=${1:-}; node=${2:-}
case "$cmd" in
  acquire)
    [ -n "$node" ] || { echo 'lease: node required' >&2; exit 2; }
    dispatch=$(sh scripts/graph-next.sh)
    [ "$dispatch" = "NEXT $node" ] || { echo "lease: expected NEXT $node, got $dispatch" >&2; exit 1; }
    base=$(git rev-parse HEAD)
    sh scripts/ledger.sh append "$agent" "$node" LEASE "holder=$agent base=$base"
    echo "lease acquire $node: ok"
    ;;
  heartbeat)
    [ -n "$node" ] || { echo 'lease: node required' >&2; exit 2; }
    sh scripts/ledger.sh append "$agent" "$node" HEARTBEAT "holder=$agent"
    echo "lease heartbeat $node: ok"
    ;;
  release)
    [ -n "$node" ] || { echo 'lease: node required' >&2; exit 2; }
    sh scripts/ledger.sh append "$agent" "$node" LEASE_RELEASE "holder=$agent"
    echo "lease release $node: ok"
    ;;
  takeover)
    [ -n "$node" ] || { echo 'lease: node required' >&2; exit 2; }
    dispatch=$(sh scripts/graph-next.sh)
    [ "$dispatch" = "RESUME $node" ] || { echo "lease: expected RESUME $node, got $dispatch" >&2; exit 1; }
    python3 scripts/lease_age_check.py "$node" 5400
    base=$(python3 scripts/lease_base.py "$node")
    sh scripts/ledger.sh append "$agent" "$node" LEASE_TAKEOVER "holder=$agent base=$base stale_after=5400"
    echo "lease takeover $node: ok"
    ;;
  *) echo 'usage: lease.sh acquire|heartbeat|release|takeover EP-XXX' >&2; exit 2;;
esac
