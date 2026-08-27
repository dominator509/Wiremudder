#!/usr/bin/env sh
# EP-009 M1 contract test: inherited classic-client surfaces must exist
# and be reachable from the build tree (WM-SPEC-005-R01..R07).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Core terminal + automation + mapper surfaces (source evidence WM-SRC-000062..000076)
for f in \
  src/TConsole.h src/TConsole.cpp \
  src/TTextEdit.h \
  src/TTrigger.h \
  src/TAlias.h \
  src/TTimer.h \
  src/TAction.h \
  src/TVar.h \
  src/TLuaInterpreter.h \
  src/dlgTriggersMainArea.h \
  src/TEvent.h \
  src/TMap.h src/T2DMap.h \
  src/dlgMapper.h \
  src/dlgPackageExporter.h \
  src/TCommandLine.h; do
  [ -f "$f" ] || fail "inherited surface missing: $f"
done

# Key symbols that parity fixtures ground on
grep -q "initiateSpeedWalk" src/T2DMap.h || fail "speedwalk symbol missing"
grep -q "class TConsole" src/TConsole.h || fail "TConsole symbol missing"
grep -q "class TTrigger" src/TTrigger.h || fail "TTrigger symbol missing"
grep -q "class TLuaInterpreter" src/TLuaInterpreter.h || fail "TLuaInterpreter missing"

echo "contract EP-009 M1: ok"
