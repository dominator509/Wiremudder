#!/usr/bin/env sh
# EP-010 M1 contract test: inherited package + scripting surfaces exist
# (source evidence WM-SRC-000076..000081).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

for f in \
  src/dlgPackageExporter.h src/dlgPackageExporter.cpp \
  src/dlgPackageManager.h src/dlgPackageManager.cpp \
  src/TLuaInterpreter.h src/TLuaInterpreter.cpp \
  src/TBuffer.h; do
  [ -f "$f" ] || fail "inherited surface missing: $f"
done

# Package install/load entry points exist on the Lua surface
grep -q "loadPackage\|installPackage" src/TLuaInterpreter.cpp || fail "package load entry missing"
grep -q "class dlgPackageManager" src/dlgPackageManager.h || fail "package manager missing"

echo "contract EP-010 M1: ok"
