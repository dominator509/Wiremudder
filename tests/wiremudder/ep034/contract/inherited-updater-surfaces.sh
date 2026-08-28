#!/usr/bin/env sh
# EP-034 M1 contract test: the inherited updater surfaces this node builds on
# exist and carry the exact anchors the node contract requires — the Updater
# class, the dblsqd feed/release/semver/dialog classes, the checksum path, and
# the CMake USE_UPDATER wiring that gates the whole subsystem.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Inherited updater surface (SPEC-020 upstream lock; never invented).
[ -f src/updater.h ] || fail "missing src/updater.h"
grep -q "class Updater" src/updater.h || fail "updater.h missing Updater class"
grep -q "INCLUDE_UPDATER" src/updater.h || fail "updater.h missing INCLUDE_UPDATER guard"
[ -f src/updater.cpp ] || fail "missing src/updater.cpp"

# Inherited dblsqd feed classes the secure updater verifies against.
[ -f src/updater/Feed.h ] || fail "missing src/updater/Feed.h"
grep -q "downloadRelease" src/updater/Feed.h || fail "Feed.h missing downloadRelease"
grep -q "findChecksum" src/updater/Feed.h || fail "Feed.h missing findChecksum"
[ -f src/updater/Release.h ] || fail "missing src/updater/Release.h"
grep -q "getDownloadSHA256" src/updater/Release.h || fail "Release.h missing getDownloadSHA256"
[ -f src/updater/SemVer.h ] || fail "missing src/updater/SemVer.h"
grep -q "class SemVer" src/updater/SemVer.h || fail "SemVer.h missing SemVer class"
[ -f src/updater/UpdateDialog.h ] || fail "missing src/updater/UpdateDialog.h"
grep -q "class UpdateDialog" src/updater/UpdateDialog.h || fail "UpdateDialog.h missing UpdateDialog class"

# The CMake wiring that gates the updater (USE_UPDATER -> INCLUDE_UPDATER).
grep -q "USE_UPDATER" src/CMakeLists.txt || fail "CMakeLists missing USE_UPDATER"
grep -q "INCLUDE_UPDATER" src/CMakeLists.txt || fail "CMakeLists missing INCLUDE_UPDATER"

# The permission surface: updater permission already canonical in the
# package boundary (EP-010) and the wire-packages core.
grep -q "Permission::Updater" src/wiremudder/packages/package_boundary.h \
  || fail "package_boundary.h missing Permission::Updater"
grep -q "Permission::Updater" wirecore/crates/wire-packages/src/lib.rs \
  || fail "wire-packages lib.rs missing Permission::Updater"

# The live-fire proof path is contractually fixed.
grep -q "LF-034" .agent/node-contracts/EP-034.md || fail "LF-034 missing from contract"

echo "contract EP-034 inherited-updater-surfaces: ok"
