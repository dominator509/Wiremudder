#!/usr/bin/env sh
# EP-012 M2 UI smoke: all three boundaries compile and pass invariants
# together (terminal + workspace + editor).
set -eu
cd "$(dirname "$0")/../../.."

QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep012-ui-smoke-$$
trap 'rm -f "$HARNESS"' EXIT

fail() { echo "ui: FAIL - $1" >&2; exit 1; }

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

"$HARNESS" terminal || fail "terminal"
"$HARNESS" workspace || fail "workspace"
"$HARNESS" editor || fail "editor"

echo "ui smoke: ok"
