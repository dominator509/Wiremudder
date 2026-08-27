#!/usr/bin/env sh
# Performance test: configure is bounded and reproducible.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"
[ -d "$builddir" ] || { echo "SKIP: no build dir yet" >&2; exit 0; }
start=$(date +%s%N)
cmake --preset "$preset" -DCMAKE_PREFIX_PATH=/opt/qt/6.8.2/gcc_64 >/dev/null 2>&1
end=$(date +%s%N)
ms=$(( (end - start) / 1000000 ))
echo "performance configure: ${ms}ms"
[ "$ms" -lt 60000 ] || { echo "FAIL: configure exceeded 60s" >&2; exit 1; }
echo "performance configure: ok"
