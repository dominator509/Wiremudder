#!/usr/bin/env sh
# Performance test: a no-op incremental build of the inherited client must
# be bounded (no full rebuild on unchanged sources). Measures warm
# steady-state after one warm-up pass.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
builddir="build-$preset"
[ -d "$builddir" ] || { echo "SKIP: no build dir yet" >&2; exit 0; }
# Warm-up: bring the tree fully up to date (records any one-time rebuild).
cmake --build --preset "$preset" >/dev/null 2>&1 || true
start=$(date +%s%N)
cmake --build --preset "$preset" >/dev/null 2>&1
end=$(date +%s%N)
ms=$(( (end - start) / 1000000 ))
echo "performance incremental-build: ${ms}ms"
[ "$ms" -lt 15000 ] || { echo "FAIL: incremental build exceeded 15s (likely full rebuild)" >&2; exit 1; }
echo "performance incremental-build: ok"
