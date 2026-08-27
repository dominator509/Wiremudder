#!/usr/bin/env sh
# Failure test: configure must fail cleanly when the Qt prefix is wrong
# (dependency-unavailable proof), without corrupting the existing build.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
set +e
cmake --preset "$preset" -DCMAKE_PREFIX_PATH="$tmpdir" >/tmp/wm-e1f-001.out 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: configure succeeded with bogus Qt prefix" >&2; exit 1; }
grep -qi "could not find\|not found\|Configuring incomplete" /tmp/wm-e1f-001.out || { echo "FAIL: expected diagnostic missing" >&2; exit 1; }
echo "failure configure-dependency-missing: ok"
