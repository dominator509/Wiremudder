#!/usr/bin/env sh
# EP-012 M3 integration: real session flow through the terminal, capture,
# history, completion, gauge, and workspace boundaries with a controlled
# text stream (SIMULATION: local in-process stream, not a live server).
set -eu
cd "$(dirname "$0")/../../../.."

QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep012-m3-int-$$
LAYOUT=$(mktemp /tmp/wm-ep012-layout-XXXX.json)
trap 'rm -f "$HARNESS" "$LAYOUT"' EXIT

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

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

# Full session flow writes the layout to a real file and restores it.
"$HARNESS" session "$LAYOUT" || fail "session flow"

# The layout file must exist and be valid JSON with the persisted state.
[ -s "$LAYOUT" ] || fail "layout file empty"
python3 - "$LAYOUT" <<'PY' || fail "layout json invalid"
import json, sys
data = json.load(open(sys.argv[1]))
assert data["name"] == "combat", data
assert any(d["id"] == "capture" for d in data["docks"]), data
assert data["gauges"][0]["id"] == "hp" and data["gauges"][0]["value"] == "63", data
assert data["theme"]["name"] == "night" and data["theme"]["highContrast"] is True, data
print("layout persisted: ok")
PY

echo "integration session-flow: ok"
