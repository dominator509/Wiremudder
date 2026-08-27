#!/usr/bin/env sh
# Failure test: the graph dispatcher must never return ALL_DONE while
# EP-000 is not closed, and must reject a lease for a node that is not
# the current dispatch.
set -eu
dispatch=$(sh scripts/graph-next.sh)
[ "$dispatch" = "NEXT EP-000" ] || [ "$dispatch" = "RESUME EP-000" ] || { echo "FAIL: unexpected dispatch $dispatch" >&2; exit 1; }
set +e
sh scripts/lease.sh acquire EP-039 >/tmp/wm-fail-004.out 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: lease acquired for non-dispatch node" >&2; exit 1; }
echo "failure lease-dispatch-bound: ok"
