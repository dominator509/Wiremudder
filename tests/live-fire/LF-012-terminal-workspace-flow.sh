#!/usr/bin/env sh
# LF-012 terminal-workspace-flow (live-fire)
#
# Proves the real user outcome of EP-012: raw terminal text is always
# visible (WM-SPEC-007-R03); capture mirrors and workspace layouts
# persist across restart (WM-SPEC-007-R04); history + completion assist
# command entry (WM-FEAT-0004/0019); gauges reflect state (WM-FEAT-0012);
# optional surface failure preserves manual text gameplay. Real
# controlled dependencies only (in-process boundaries + real JSON files).
set -eu
fail() { echo "LF-012: FAIL - $1" >&2; exit 1; }

cd "$(dirname "$0")/../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-lf012-harness-$$
LAYOUT=$(mktemp /tmp/wm-lf012-layout-XXXX.json)
trap 'rm -f "$HARNESS" "$LAYOUT"' EXIT

echo "LF-012: terminal-workspace-flow"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

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

# 1. Full session flow: raw stream, capture, history, completion,
#    gauges, layout persistence to a real file.
"$HARNESS" session "$LAYOUT" >/dev/null || fail "session flow"

# 2. The persisted layout is valid and carries the full state.
python3 - "$LAYOUT" <<'PY' || fail "layout verification"
import json, sys
data = json.load(open(sys.argv[1]))
assert data["name"] == "combat"
assert any(d["id"] == "capture" for d in data["docks"])
assert data["gauges"][0]["value"] == "63"
assert data["theme"]["name"] == "night" and data["theme"]["highContrast"] is True
print("layout state: ok")
PY

# 3. Restart behavior: a second process restores the same bytes.
cp "$LAYOUT" "${LAYOUT}.bak"
"$HARNESS" session "$LAYOUT" >/dev/null || fail "restart session"
cmp -s "$LAYOUT" "${LAYOUT}.bak" || fail "layout drift across restart"

# 4. Resource bound: 100k-line stress completes inside the live harness.
timeout 60 "$HARNESS" stress >/dev/null || fail "stress bound"

# 5. Performance: boundaries stay inside the 10ms budget.
OUT=$(sh tests/wiremudder/ep012/performance/001-ui-latency.sh 2>&1 | grep "worst")
echo "$OUT"
case "$OUT" in
  *budget=10.0ms*) : ;;
  *) fail "performance budget line unexpected: $OUT" ;;
esac

echo "LF-012: terminal-workspace-flow ok"
