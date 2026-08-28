#!/usr/bin/env sh
# EP-026 M3 integration test: the soundscape UI boundary must compile
# against the real Qt6 toolchain with zero warnings, and the CMake
# source list must include the boundary (build-integration contract).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

QTDIR=/opt/qt/6.8.2/gcc_64
[ -d "$QTDIR/include/QtCore" ] || fail "Qt6 not found at $QTDIR"

out=$(mktemp /tmp/ep026_boundary_XXXX.log)
g++ -std=c++17 -fPIC -c src/wiremudder/ui/soundscape/soundscape_boundary.cpp \
  -o /tmp/ep026_soundscape_boundary.o \
  -I"$QTDIR/include" -I"$QTDIR/include/QtCore" -Wall -Wextra 2>"$out" || {
  cat "$out" >&2
  fail "soundscape boundary did not compile against Qt6"
}
if grep -q "warning:" "$out"; then
  cat "$out" >&2
  fail "soundscape boundary compiled with warnings"
fi

# Passive surface invariants must exist in the boundary header.
grep -q "isPassive() const { return true; }" src/wiremudder/ui/soundscape/soundscape_boundary.h \
  || fail "boundary is not passive"
grep -q "canSendCommand() const { return false; }" src/wiremudder/ui/soundscape/soundscape_boundary.h \
  || fail "boundary has a command path"

echo "integration EP-026 soundscape-boundary-qt6: ok"
