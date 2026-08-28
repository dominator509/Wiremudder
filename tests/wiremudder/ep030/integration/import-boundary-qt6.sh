#!/usr/bin/env sh
# EP-030 M3 integration test: the import UI boundary must compile against
# the real Qt6 toolchain with zero warnings, and the CMake source list
# must include the boundary (build-integration contract).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

QTDIR=/opt/qt/6.8.2/gcc_64
[ -d "$QTDIR/include/QtCore" ] || fail "Qt6 not found at $QTDIR"

out=$(mktemp /tmp/ep030_boundary_XXXX.log)
g++ -std=c++17 -fPIC -c src/wiremudder/ui/import/import_boundary.cpp \
  -o /tmp/ep030_import_boundary.o \
  -I"$QTDIR/include" -I"$QTDIR/include/QtCore" -Wall -Wextra 2>"$out" || {
  cat "$out" >&2
  fail "import boundary did not compile against Qt6"
}
if grep -q "warning:" "$out"; then
  cat "$out" >&2
  fail "import boundary compiled with warnings"
fi

# Passive surface invariants must exist in the boundary header.
grep -q "bool isPassive() const { return true; }" src/wiremudder/ui/import/import_boundary.h \
  || fail "boundary is not passive"
grep -q "bool canExecuteImport() const { return false; }" src/wiremudder/ui/import/import_boundary.h \
  || fail "boundary can execute imports"
grep -q "bool canEnableAutomation() const { return false; }" src/wiremudder/ui/import/import_boundary.h \
  || fail "boundary can enable automation"
grep -q "bool canSendCommand() const { return false; }" src/wiremudder/ui/import/import_boundary.h \
  || fail "boundary has a command path"
grep -q "bool canAccessSecrets() const { return false; }" src/wiremudder/ui/import/import_boundary.h \
  || fail "boundary can access secrets"
grep -q "bool canEgress() const { return false; }" src/wiremudder/ui/import/import_boundary.h \
  || fail "boundary has an egress path"
grep -q "bool automationDisabledByDefault() const { return true; }" src/wiremudder/ui/import/import_boundary.h \
  || fail "automation not disabled by default"

# The CMake source list includes the boundary beside help.
grep -q "wiremudder/ui/import/import_boundary.cpp" src/CMakeLists.txt \
  || fail "import boundary not in mudlet_SRCS"
grep -q "wiremudder/ui/import/import_boundary.h" src/CMakeLists.txt \
  || fail "import boundary header not in UI headers"

echo "integration EP-030 import-boundary-qt6: ok"
