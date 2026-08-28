#!/usr/bin/env sh
# EP-018 contract test: the Soul UI boundary must be compiled into the
# actual Mudlet-derived client. Every client .cpp is listed explicitly in
# src/CMakeLists.txt (set(mudlet_SRCS ...)); a Soul UI source that exists
# on disk but is absent from that list is dead, unwired code.
#
# Authorized by discovered-path amendment (WM-SRC-000120): src/CMakeLists.txt
# is the smallest inherited integration patch for the Soul UI boundary.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f src/CMakeLists.txt ] || fail "src/CMakeLists.txt missing"
grep -q "^set(mudlet_SRCS" src/CMakeLists.txt || fail "mudlet_SRCS list missing"

# Every Soul UI source file must be listed in the build (src-relative path).
for f in src/wiremudder/ui/soul/*.cpp; do
  [ -e "$f" ] || continue
  rel=${f#src/}
  grep -qE "^    ${rel}$" src/CMakeLists.txt \
    || fail "Soul UI source ${f} exists but is not compiled (add ${rel} to mudlet_SRCS in src/CMakeLists.txt)"
done

echo "contract soul-build-integration: ok"
