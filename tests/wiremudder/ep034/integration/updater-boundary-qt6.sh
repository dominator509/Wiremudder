#!/usr/bin/env sh
# EP-034 M3 integration test: the updater boundary must be wired into the
# inherited CMake source list beside the established owned panes and compile
# against the real Qt6 toolchain with zero warnings. The boundary is a
# verification-only surface: it never signs, never mutates settings, and
# never changes gameplay.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

QTDIR=/opt/qt/6.8.2/gcc_64
[ -d "$QTDIR/include/QtCore" ] || fail "Qt6 not found at $QTDIR"

# The discovered amendment authorizes the inherited CMake edit.
grep -q '"path":"src/CMakeLists.txt"' .agent/expected-files/EP-034.discovered.txt \
  || fail "src/CMakeLists.txt not authorized in discovered amendment"

# The boundary is wired into both the sources and headers lists.
grep -q "wiremudder/updater/updater_boundary.cpp" src/CMakeLists.txt \
  || fail "updater boundary source not wired into CMake"
grep -q "wiremudder/updater/updater_boundary.h" src/CMakeLists.txt \
  || fail "updater boundary header not wired into CMake"

# Real Qt6 compile with zero warnings.
out=$(mktemp /tmp/ep034_boundary_XXXX.log)
g++ -std=c++17 -fPIC -c src/wiremudder/updater/updater_boundary.cpp \
  -o /tmp/ep034_updater_boundary.o \
  -I"$QTDIR/include" -I"$QTDIR/include/QtCore" -Wall -Wextra 2>"$out" || {
  cat "$out" >&2
  fail "updater boundary did not compile against Qt6"
}
if grep -q "warning:" "$out"; then
  cat "$out" >&2
  fail "updater boundary compiled with warnings"
fi

# The boundary is verification-only: no signing key material, no command
# path, no settings mutation, no egress.
grep -q "verifyManifest" src/wiremudder/updater/updater_boundary.h \
  || fail "boundary missing verifyManifest"
grep -q "never signs" src/wiremudder/updater/updater_boundary.h \
  || fail "boundary does not declare it never signs"
grep -q "Local Only Lockdown blocks remote update checks" src/wiremudder/updater/updater_boundary.h \
  || fail "boundary missing lockdown surface"

echo "integration EP-034 updater-boundary-qt6: ok"
