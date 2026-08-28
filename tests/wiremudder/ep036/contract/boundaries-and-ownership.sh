#!/usr/bin/env sh
# EP-036 M1 contract test: authorized boundaries and owned requirements are
# declared in the node contract and traces exactly as the graph requires.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-036.md ] || fail "missing node contract"

for b in tests/wiremudder/platform/ tests/wiremudder/chaos/ \
         compatibility/platform/ docs/wiremudder/certification/; do
  grep -q "$b" .agent/node-contracts/EP-036.md \
    || fail "authorized boundary $b missing from contract"
done

for r in WM-SPEC-019-R02 WM-SPEC-027-R08; do
  grep -q "$r" .agent/node-contracts/EP-036.md \
    || fail "owned requirement $r missing from contract"
  grep -q "$r" .agent/requirements/VALIDATION_MATRIX.tsv \
    || fail "owned requirement $r missing from validation matrix"
done

grep -q "EP-036" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "EP-036 missing from validation matrix"

for f in WM-FEAT-0159 WM-FEAT-0242; do
  grep -q "$f" .agent/features/FEATURES.tsv \
    || fail "owned feature $f missing from feature catalog"
  grep -q "$f" .agent/node-contracts/EP-036.md \
    || fail "owned feature $f missing from contract"
done

echo "contract EP-036 boundaries-and-ownership: ok"
