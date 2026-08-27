#!/usr/bin/env sh
# Failure test: CMake configure into an existing build dir with a second
# generator must fail (documented upstream pitfall) rather than corrupt.
# Runs in a temp dir so the real baseline build dir is never touched.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
# First configure with Ninja (the preset generator) into the temp dir.
cmake --preset "$preset" -B "$tmpdir/bld" -DCMAKE_PREFIX_PATH=/opt/qt/6.8.2/gcc_64 >/dev/null 2>&1 || { echo "SKIP: temp configure failed" >&2; exit 0; }
set +e
cmake -S . -B "$tmpdir/bld" -G "Unix Makefiles" >/tmp/wm-e1f-003.out 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: generator switch succeeded" >&2; exit 1; }
echo "failure generator-switch-rejected: ok"
