#!/usr/bin/env sh
# EP-034 M1/M3 contract test: the updater boundary joins the inherited
# CMakeLists source list exactly beside the owned panes, gated by the
# USE_UPDATER block. At M1 this verifies the amendment declares the wiring
# pattern and the inherited anchors exist; at M3 it verifies the real
# compiled boundary (real Qt6 build proof lives in the M3 integration/e2e
# suite).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f src/CMakeLists.txt ] || fail "missing src/CMakeLists.txt"

# The discovered amendment authorizes the inherited edit.
grep -q '"path":"src/CMakeLists.txt"' .agent/expected-files/EP-034.discovered.txt \
  || fail "src/CMakeLists.txt not authorized in discovered amendment"

# The inherited updater surface anchors exist (USE_UPDATER gates INCLUDE_UPDATER).
grep -q "USE_UPDATER" src/CMakeLists.txt || fail "USE_UPDATER anchor missing from CMakeLists"
grep -q "INCLUDE_UPDATER" src/CMakeLists.txt || fail "INCLUDE_UPDATER anchor missing from CMakeLists"

# The boundary joins beside the established owned panes (anchor exists).
grep -q "wiremudder/ui/soundscape/soundscape_boundary.cpp" src/CMakeLists.txt \
  || fail "soundscape anchor missing from CMakeLists"
grep -q "wiremudder/accessibility/accessibility_boundary.cpp" src/CMakeLists.txt \
  || fail "accessibility anchor missing from CMakeLists"

echo "contract EP-034 updater-build-integration: ok"
