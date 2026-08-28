#!/usr/bin/env sh
# EP-031 M1 contract test: authorized boundaries and owned requirement are
# declared in the node contract exactly as the graph requires.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-031.md ] || fail "missing node contract"

for b in src/wiremudder/accessibility/ tests/wiremudder/accessibility/ \
         docs/wiremudder/accessibility/ translations/wiremudder/; do
  grep -q "$b" .agent/node-contracts/EP-031.md \
    || fail "authorized boundary $b missing from contract"
done

grep -q "WM-SPEC-007-R10" .agent/node-contracts/EP-031.md \
  || fail "owned WM-SPEC-007-R10 missing from contract"

grep -q "WM-SPEC-007-R10" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "WM-SPEC-007-R10 missing from validation matrix"
grep -q "EP-031" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "EP-031 missing from validation matrix"

echo "contract EP-031 boundaries-and-ownership: ok"
