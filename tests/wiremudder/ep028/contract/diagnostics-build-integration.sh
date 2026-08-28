#!/usr/bin/env sh
# EP-028 contract test: the diagnostics UI boundary must be compiled into
# the actual Mudlet-derived client. Every client .cpp is listed explicitly
# in src/CMakeLists.txt (set(mudlet_SRCS ...)); a diagnostics UI source that
# exists on disk but is absent from that list is dead, unwired code.
#
# Authorized by discovered-path amendment: src/CMakeLists.txt is the
# smallest inherited integration patch for the diagnostics UI.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f src/CMakeLists.txt ] || fail "src/CMakeLists.txt missing"
grep -q "^set(mudlet_SRCS" src/CMakeLists.txt || fail "mudlet_SRCS list missing"

# Every diagnostics UI source file must be listed in the build.
for f in src/wiremudder/ui/diagnostics/*.cpp; do
  [ -e "$f" ] || continue
  rel=${f#src/}
  grep -qE "^    ${rel}$" src/CMakeLists.txt \
    || fail "diagnostics UI source ${f} exists but is not compiled (add ${rel} to mudlet_SRCS)"
done

echo "contract diagnostics-build-integration: ok"
