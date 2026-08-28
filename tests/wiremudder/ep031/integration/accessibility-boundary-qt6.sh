#!/usr/bin/env sh
# EP-031 M3 integration test: the accessibility boundary must be wired into
# the inherited CMake source list beside the established owned panes and
# compile against the real Qt6 toolchain with zero warnings.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

QTDIR=/opt/qt/6.8.2/gcc_64
[ -d "$QTDIR/include/QtCore" ] || fail "Qt6 not found at $QTDIR"

out=$(mktemp /tmp/ep031_boundary_XXXX.log)
g++ -std=c++17 -fPIC -c src/wiremudder/accessibility/accessibility_boundary.cpp \
  -o /tmp/ep031_accessibility_boundary.o \
  -I"$QTDIR/include" -I"$QTDIR/include/QtCore" -Wall -Wextra 2>"$out" || {
  cat "$out" >&2
  fail "accessibility boundary did not compile against Qt6"
}
if grep -q "warning:" "$out"; then
  cat "$out" >&2
  fail "accessibility boundary compiled with warnings"
fi

# Passive surface invariants must exist in the boundary header.
grep -q "bool isPassive() const { return true; }" src/wiremudder/accessibility/accessibility_boundary.h \
  || fail "boundary is not passive"
grep -q "bool canSendCommand() const { return false; }" src/wiremudder/accessibility/accessibility_boundary.h \
  || fail "boundary has a command path"
grep -q "bool canChangeSettings() const { return false; }" src/wiremudder/accessibility/accessibility_boundary.h \
  || fail "boundary can change settings"
grep -q "bool canAccessSecrets() const { return false; }" src/wiremudder/accessibility/accessibility_boundary.h \
  || fail "boundary can access secrets"
grep -q "bool canEgress() const { return false; }" src/wiremudder/accessibility/accessibility_boundary.h \
  || fail "boundary has an egress path"
grep -q "bool canDisableRawText() const { return false; }" src/wiremudder/accessibility/accessibility_boundary.h \
  || fail "boundary can disable raw text"
grep -q "bool rawTextAlwaysVisible() const { return true; }" src/wiremudder/accessibility/accessibility_boundary.h \
  || fail "raw text not always visible"
grep -q "bool translatorContextRequired() const { return true; }" src/wiremudder/accessibility/accessibility_boundary.h \
  || fail "translator context not required"

# The CMake source list includes the boundary beside help/import.
grep -q "wiremudder/accessibility/accessibility_boundary.cpp" src/CMakeLists.txt \
  || fail "accessibility boundary not in mudlet_SRCS"
grep -q "wiremudder/accessibility/accessibility_boundary.h" src/CMakeLists.txt \
  || fail "accessibility boundary header not in UI headers"

echo "integration EP-031 accessibility-boundary-qt6: ok"
