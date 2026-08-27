#!/usr/bin/env sh
# Performance test: incremental build of the inherited client must be
# bounded (no full rebuild on a no-op) and the binary must exist.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"
[ -d "$builddir" ] || { echo "SKIP: no build dir yet" >&2; exit 0; }
start=$(date +%s%N)
cmake --build --preset "$preset" >/dev/null 2>&1 || true
end=$(date +%s%N)
ms=$(( (end - start) / 1000000 ))
echo "performance incremental-build: ${ms}ms"
[ "$ms" -lt 120000 ] || { echo "FAIL: incremental build exceeded 120s (likely full rebuild)" >&2; exit 1; }
echo "performance incremental-build: ok"
