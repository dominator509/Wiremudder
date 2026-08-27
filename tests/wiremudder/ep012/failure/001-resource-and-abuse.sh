#!/usr/bin/env sh
# EP-012 M4 failure test: resource exhaustion, malformed input, duplicate
# request, denied policy, partial effect. Real controlled mechanisms.
set -eu
cd "$(dirname "$0")/../../../.."

QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep012-m4-fail-$$
trap 'rm -f "$HARNESS"' EXIT

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

[ -d "$QT" ] || fail "Qt 6.8.2 not at $QT"
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core) \
  -I"$PWD" \
  tests/wiremudder/ep012/harness/ep012_harness.cpp \
  src/wiremudder/ui/terminal_boundary.cpp \
  src/wiremudder/ui/workspace_boundary.cpp \
  src/wiremudder/ui/editor_boundary.cpp \
  $(pkg-config --libs Qt6Core) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || fail "harness compile"

timeout 60 "$HARNESS" stress || fail "stress boundary"

echo "failure resource-and-abuse: ok"
