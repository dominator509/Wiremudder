#!/usr/bin/env sh
# EP-007 M4 failure test: timeout and cancellation. A route whose
# endpoint cannot be reached within the timeout must fail fast with a
# typed error and never hang the connection attempt.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep007-m4-to-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep007/harness/ep007_harness.cpp \
  src/wiremudder/profiles/character_profile_store.cpp \
  src/wiremudder/routing/route_profile_store.cpp \
  src/wiremudder/routing/router.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

# The harness failures subcommand includes a connect to a closed port
# with a 400ms timeout: it must block with an error, not hang.
start=$(date +%s%N)
if LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" failures >/dev/null 2>&1; then
  :
else
  echo "FAIL: harness failures" >&2
  exit 1
fi
end=$(date +%s%N)
elapsed_ms=$(( (end - start) / 1000000 ))
# The whole failures matrix (including the 400ms timeout) must finish
# within 30 seconds; a hang would blow this bound.
if [ "$elapsed_ms" -gt 30000 ]; then
  echo "FAIL: timeout test exceeded 30s bound (${elapsed_ms}ms)" >&2
  exit 1
fi

echo "failure timeout-cancellation: ok (elapsed ${elapsed_ms}ms)"
