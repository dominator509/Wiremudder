#!/usr/bin/env sh
# Failure test: the graph dispatcher must never return ALL_DONE while
# work remains, and a lease must be rejected for a node that is not the
# current dispatch.
set -eu
dispatch=$(sh scripts/graph-next.sh)
case "$dispatch" in
  "NEXT EP-"[0-9][0-9][0-9]|"RESUME EP-"[0-9][0-9][0-9]|"BLOCKED EP-"[0-9][0-9][0-9]) ;;
  *) echo "FAIL: unexpected dispatch $dispatch" >&2; exit 1 ;;
esac
current=${dispatch##* }
# Choose a node guaranteed not to be the current dispatch.
if [ "$current" = "EP-000" ]; then
  other=EP-039
else
  other=EP-000
fi
set +e
sh scripts/lease.sh acquire "$other" >/tmp/wm-fail-004.out 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: lease acquired for non-dispatch node $other" >&2; exit 1; }
echo "failure lease-dispatch-bound: ok"
