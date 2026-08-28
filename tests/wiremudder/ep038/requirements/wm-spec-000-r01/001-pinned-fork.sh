#!/usr/bin/env sh
# WM-SPEC-000-R01: WireMudder starts from a pinned, attribution-preserving
# Mudlet fork and does not require a complete rewrite before first release.
# Proven with real repository evidence for the release candidate.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "r01: FAIL - $1" >&2; exit 1; }

# 1. The upstream fork is pinned and attribution-preserving.
[ -f UPSTREAM.lock.yaml ] || fail "UPSTREAM.lock.yaml missing"
grep -q "77086c295f4adf59197e586e689d19bdde8e1008" UPSTREAM.lock.yaml \
  || fail "pinned upstream commit missing from lock"
git cat-file -e 77086c295f4adf59197e586e689d19bdde8e1008^{commit} 2>/dev/null \
  || fail "pinned upstream commit not present in repository"

# 2. The candidate records the same upstream pin (manifest + provenance).
cand=release/wiremudder/candidate
grep -q "77086c295f4adf59197e586e689d19bdde8e1008" "$cand/manifest.json" \
  || fail "manifest lacks upstream pin"
grep -q "77086c295f4adf59197e586e689d19bdde8e1008" "$cand/provenance.json" \
  || fail "provenance lacks upstream pin"

# 3. No rewrite: the pinned commit is an ancestor of the release source.
src_commit=$(python3 -c "import json;print(json.load(open('$cand/manifest.json'))['source_commit'])")
git merge-base --is-ancestor 77086c295f4adf59197e586e689d19bdde8e1008 "$src_commit" \
  || fail "pinned commit not ancestor of candidate source"

echo "requirement wm-spec-000-r01: ok"
