#!/usr/bin/env sh
# EP-031 M2 unit test: the accessibility boundary must compile against the
# real Qt6 toolchain with zero warnings and its deterministic model
# invariants must hold (passive surface, raw text always visible,
# translator context required, catalog convention). The unit harness
# asserts every core rule and returns non-zero on failure.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

QTDIR=/opt/qt/6.8.2/gcc_64
[ -d "$QTDIR/include/QtCore" ] || fail "Qt6 not found at $QTDIR"

out=$(mktemp /tmp/ep031_unit_XXXX.log)
g++ -std=c++17 -fPIC -I"$QTDIR/include" -I"$QTDIR/include/QtCore" \
  -I src \
  tests/wiremudder/accessibility/unit_harness.cpp \
  src/wiremudder/accessibility/accessibility_boundary.cpp \
  -L"$QTDIR/lib" -Wl,-rpath,"$QTDIR/lib" -lQt6Core \
  -o /tmp/ep031_unit_harness 2>"$out" || {
  cat "$out" >&2
  fail "accessibility boundary did not compile against Qt6"
}
if grep -q "warning:" "$out"; then
  cat "$out" >&2
  fail "accessibility boundary compiled with warnings"
fi

LD_LIBRARY_PATH="$QTDIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  /tmp/ep031_unit_harness >"$out" 2>&1 || {
  cat "$out" >&2
  fail "unit harness failed"
}
grep -q "unit accessibility-boundary: ok" "$out" || fail "harness sentinel missing"

# The passive-surface invariants must exist in the boundary header.
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

echo "unit accessibility-boundary: ok"
