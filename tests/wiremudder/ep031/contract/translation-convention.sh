#!/usr/bin/env sh
# EP-031 M1 contract test: the inherited Mudlet translation convention is
# the exact convention WM-SPEC-007-R10 requires new strings to follow.
# This test locks the anchors so M2/M3 translation work must match them.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f translations/mudlet.ts ] || fail "missing master translations/mudlet.ts"

# Locale catalogs live under translations/translated/ with mudlet_<locale>.ts.
[ -f translations/translated/mudlet_de_DE.ts ] || fail "missing locale catalog mudlet_de_DE.ts"

# Compiled catalogs are registered in qm.qrc under the /lang prefix.
grep -q '/lang' translations/translated/qm.qrc || fail "qm.qrc missing /lang prefix"

# The build requires Qt6LinguistTools and compiles .ts via lrelease.
grep -q 'Qt6LinguistTools 6.8.2 REQUIRED' translations/translated/CMakeLists.txt \
  || fail "translated build does not require Qt6LinguistTools"
grep -q 'lrelease' translations/translated/CMakeLists.txt \
  || fail "translated build does not invoke lrelease"

# The runtime loads the catalog from the :/lang resource with catalog name
# "mudlet" and the .qm suffix (the convention new catalogs must follow).
grep -q 'mudlet' src/main.cpp || fail "runtime translator missing mudlet catalog"
grep -q ':/lang' src/main.cpp || fail "runtime translator missing :/lang resource"

echo "contract EP-031 translation-convention: ok"
