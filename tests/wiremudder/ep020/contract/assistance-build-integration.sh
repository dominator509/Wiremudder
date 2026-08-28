#!/usr/bin/env sh
# EP-020 contract test: the assistance UI boundary must be compiled into
# the actual Mudlet-derived client. Every client .cpp is listed explicitly
# in src/CMakeLists.txt (set(mudlet_SRCS ...)); an assistance UI source
# that exists on disk but is absent from that list is dead, unwired code.
#
# Authorized by discovered-path amendment (WM-SRC-000136): src/CMakeLists.txt
# is the smallest inherited integration patch for the assistance UI.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f src/CMakeLists.txt ] || fail "src/CMakeLists.txt missing"
grep -q "^set(mudlet_SRCS" src/CMakeLists.txt || fail "mudlet_SRCS list missing"

# Every assistance UI source file must be listed in the build.
for f in src/wiremudder/ui/assistance/*.cpp; do
  [ -e "$f" ] || continue
  rel=${f#src/}
  grep -qE "^    ${rel}$" src/CMakeLists.txt \
    || fail "assistance UI source ${f} exists but is not compiled (add ${rel} to mudlet_SRCS)"
done

echo "contract assistance-build-integration: ok"
