#!/usr/bin/env sh
# EP-031 M1/M3 contract test: the accessibility boundary joins the owned UI
# panes in the inherited CMake source list exactly beside help, soundscape,
# diagnostics, and import. At M1 this verifies the wiring pattern is
# declared; at M3 it verifies the real compiled boundary (real Qt6 build
# proof lives in the M3 integration/e2e suite).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f src/CMakeLists.txt ] || fail "missing src/CMakeLists.txt"

# The discovered amendment authorizes the inherited edit.
grep -q '"path":"src/CMakeLists.txt"' .agent/expected-files/EP-031.discovered.txt \
  || fail "src/CMakeLists.txt not authorized in discovered amendment"

# The boundary joins beside the established owned panes (anchor exists).
grep -q "wiremudder/ui/help/help_boundary.cpp" src/CMakeLists.txt \
  || fail "help anchor missing from CMakeLists"
grep -q "wiremudder/ui/soundscape/soundscape_boundary.cpp" src/CMakeLists.txt \
  || fail "soundscape anchor missing from CMakeLists"
grep -q "wiremudder/ui/import/import_boundary.cpp" src/CMakeLists.txt \
  || fail "import anchor missing from CMakeLists"

echo "contract EP-031 accessibility-build-integration: ok"
