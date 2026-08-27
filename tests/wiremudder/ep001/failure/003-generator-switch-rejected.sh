#!/usr/bin/env sh
# Failure test: CMake configure into an existing build dir with a second
# generator must fail (documented upstream pitfall) rather than corrupt.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"
[ -d "$builddir" ] || { echo "SKIP: no build dir yet" >&2; exit 0; }
set +e
cmake -S . -B "$builddir" -G "Unix Makefiles" >/tmp/wm-e1f-003.out 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: generator switch succeeded" >&2; exit 1; }
echo "failure generator-switch-rejected: ok"
