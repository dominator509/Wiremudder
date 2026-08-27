#!/usr/bin/env sh
# EP-013 M1 contract test: inherited mapper/world-graph/routing surfaces
# exist (source evidence WM-SRC-000094..000100).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

for f in \
  src/TMap.h src/TMap.cpp \
  src/TRoom.h src/TRoom.cpp \
  src/TArea.h src/TArea.cpp \
  src/TAstar.h \
  src/TMapView.h src/TMapView.cpp \
  src/T2DMap.h src/T2DMap.cpp \
  src/TMapViewManager.h src/TMapViewManager.cpp; do
  [ -f "$f" ] || fail "inherited mapper surface missing: $f"
done

# Map data model authority (WM-FEAT-0165..0168, WM-SPEC-005-R07).
grep -q "class TMap" src/TMap.h || fail "TMap missing"
grep -q "gotoRoom" src/TMap.h || fail "TMap::gotoRoom missing"
grep -q "importMap" src/TMap.h || fail "TMap::importMap missing"
# Room exit model: special exits, locks, weights, doors, stubs (WM-FEAT-0166).
grep -q "class TRoom" src/TRoom.h || fail "TRoom missing"
grep -q "getSpecialExits" src/TRoom.h || fail "TRoom special exits missing"
grep -q "getExitWeights" src/TRoom.h || fail "TRoom exit weights missing"
grep -q "setDoor" src/TRoom.h || fail "TRoom doors missing"
grep -q "exitStubs" src/TRoom.h || fail "TRoom exit stubs missing"
# Area/zone clustering (WM-FEAT-0165).
grep -q "class TArea" src/TArea.h || fail "TArea missing"
grep -q "isZone" src/TArea.h || fail "TArea zone flag missing"
grep -q "zoneAreaRef" src/TArea.h || fail "TArea zone ref missing"
# Boost A* routing primitives (WM-FEAT-0167).
grep -q "astar_goal_visitor" src/TAstar.h || fail "TAstar A* primitives missing"
# Map views (WM-FEAT-0165).
grep -q "class TMapView" src/TMapView.h || fail "TMapView missing"
grep -q "class T2DMap" src/T2DMap.h || fail "T2DMap missing"
grep -q "class TMapViewManager" src/TMapViewManager.h || fail "TMapViewManager missing"

echo "contract EP-013 M1: ok"
