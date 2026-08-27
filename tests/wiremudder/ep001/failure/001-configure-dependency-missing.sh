#!/usr/bin/env sh
# Failure test: configure must fail cleanly when Qt 6.8.2 is unavailable
# (dependency-unavailable proof), from a fresh build directory.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
set +e
cmake --preset "$preset" -B "$tmpdir/fresh" -DCMAKE_PREFIX_PATH="$tmpdir/empty" >/tmp/wm-e1f-001.out 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: configure succeeded with bogus Qt prefix" >&2; exit 1; }
grep -qi "could not find\|not found\|Configuring incomplete" /tmp/wm-e1f-001.out || { echo "FAIL: expected diagnostic missing" >&2; exit 1; }
echo "failure configure-dependency-missing: ok"
