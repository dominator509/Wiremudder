#!/usr/bin/env sh
# Integration test: inherited client binary exists, is executable, and
# links against Qt 6.8.2.
set -eu
. ./.env
preset=$WIREMUDDER_CMAKE_PRESET
bin="build-$preset/src/mudlet"
[ -x "$bin" ] || { echo "FAIL: $bin not executable" >&2; exit 1; }
ldd "$bin" 2>/dev/null | grep -q "libQt6Core" || { echo "FAIL: binary does not link Qt6Core" >&2; exit 1; }
ldd "$bin" 2>/dev/null | grep "libQt6Core.so.6 =>" | grep -q "/opt/qt/6.8.2/" || { echo "FAIL: binary not linked against Qt 6.8.2" >&2; exit 1; }
echo "integration client-binary: ok"
