#!/usr/bin/env sh
set -eu
LEDGER=.agent/state/LEDGER.md
[ -f "$LEDGER" ] || { echo "ledger: missing $LEDGER" >&2; exit 1; }
cmd=${1:-}
[ -n "$cmd" ] && shift || true
case "$cmd" in
  append)
    agent=${1:?agent id}; node=${2:?node id or -}; event=${3:?event}; shift 3
    detail=${*:-}
    case "$detail" in *' | '*) echo 'ledger: detail may not contain pipe delimiter' >&2; exit 2;; esac
    case "$event" in
      RUN_INIT|PREFLIGHT_OK|LEASE|HEARTBEAT|MILESTONE_PASS|ATTEMPT_FAIL|SIG|FALLBACK_TAKEN|ROLLBACK|NODE_DONE|NODE_BLOCKED|LEASE_RELEASE|LEASE_TAKEOVER|RUN_COMPLETE|DECISION|SOURCE_EVIDENCE) ;;
      *) echo "ledger: invalid event $event" >&2; exit 2;;
    esac
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    printf '%s | %s | %s | %s | %s\n' "$ts" "$agent" "$node" "$event" "$detail" >> "$LEDGER"
    ;;
  status)
    node=${1:?node id}
    line=$(grep -E "\\| $node \\| (NODE_DONE|NODE_BLOCKED|LEASE_RELEASE|LEASE_TAKEOVER|LEASE) \\|" "$LEDGER" | tail -n 1 || true)
    case "$line" in
      *'| NODE_DONE |'*) echo DONE;;
      *'| NODE_BLOCKED |'*) echo BLOCKED;;
      *'| LEASE_RELEASE |'*) echo PENDING;;
      *'| LEASE |'*|*'| LEASE_TAKEOVER |'*) echo IN_PROGRESS;;
      *) echo PENDING;;
    esac
    ;;
  last)
    node=${1:?node id}
    grep -F "| $node |" "$LEDGER" | tail -n 1 || true
    ;;
  tail)
    n=${1:-40}; tail -n "$n" "$LEDGER";;
  *) echo 'usage: ledger.sh append|status|last|tail' >&2; exit 2;;
esac
