#!/usr/bin/env sh
# EP-037 M2 unit test: every enabled (required) feature in the catalog is
# documented in the user docs. The feature index must mention every required
# feature id, and the docs must not claim research features are implemented.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -f .agent/features/FEATURES.tsv ] || fail "missing feature catalog"
[ -f docs/wiremudder/user/feature-index.md ] || fail "missing feature index"

# Every required feature id appears in the feature index.
tail -n +2 .agent/features/FEATURES.tsv | \
awk -F'\t' '$2=="required" {print $1}' | while read -r id; do
  if ! grep -q "$id" docs/wiremudder/user/feature-index.md; then
    echo "unit: missing documentation for $id" >&2
    exit 1
  fi
done || fail "required features missing from user docs"

# Research features are honestly labeled, not claimed implemented.
if grep -q "WM-FEAT-0035.*implemented" docs/wiremudder/user/feature-index.md; then
  fail "research feature labeled implemented"
fi

# The docs never claim an optional provider is certified.
if grep -rq "certified working" docs/wiremudder/user/; then
  fail "docs claim optional provider certification"
fi

echo "unit EP-037 feature-documentation: ok"
