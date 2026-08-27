#!/usr/bin/env sh
# Failure test: build must fail on a forced invalid source (malformed
# input), proving the toolchain fails closed rather than succeeding.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"
[ -d "$builddir" ] || { echo "SKIP: no build dir yet" >&2; exit 0; }
# Create a deliberately broken TU outside any source dir but inside the
# build dir, then compile it with the project compiler flags.
broken="$builddir/broken-probe.cpp"
printf 'int main( { return 0; }\n' > "$broken"
trap 'rm -f "$broken"' EXIT
set +e
c++ -c "$broken" -o "$builddir/broken-probe.o" >/tmp/wm-e1f-002.out 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: malformed source compiled" >&2; exit 1; }
echo "failure malformed-input-fails-closed: ok"
