#!/usr/bin/env sh
# EP-019 contract test: the Autopilot UI boundary must be compiled into the
# actual Mudlet-derived client. Every client .cpp is listed explicitly in
# src/CMakeLists.txt (set(mudlet_SRCS ...)); an Autopilot UI source that
# exists on disk but is absent from that list is dead, unwired code.
#
# Authorized by discovered-path amendment (WM-SRC-000124): src/CMakeLists.txt
# is the smallest inherited integration patch for the Autopilot UI boundary.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f src/CMakeLists.txt ] || fail "src/CMakeLists.txt missing"
grep -q "^set(mudlet_SRCS" src/CMakeLists.txt || fail "mudlet_SRCS list missing"

# Every Autopilot UI source file must be listed in the build (src-relative path).
for f in src/wiremudder/ui/autopilot/*.cpp; do
  [ -e "$f" ] || continue
  rel=${f#src/}
  grep -qE "^    ${rel}$" src/CMakeLists.txt \
    || fail "Autopilot UI source ${f} exists but is not compiled (add ${rel} to mudlet_SRCS in src/CMakeLists.txt)"
done

echo "contract autopilot-build-integration: ok"
