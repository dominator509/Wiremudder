#!/usr/bin/env sh
# EP-033 M1 contract test: authorized boundaries and owned requirements are
# declared in the node contract and traces exactly as the graph requires.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-033.md ] || fail "missing node contract"

for b in docs/wiremudder/security/ security/wiremudder/ sbom/wiremudder/ \
         licenses/wiremudder/ tests/wiremudder/security/; do
  grep -q "$b" .agent/node-contracts/EP-033.md \
    || fail "authorized boundary $b missing from contract"
done

for r in WM-SPEC-001-R03 WM-SPEC-001-R08 WM-SPEC-020-R02 WM-SPEC-020-R03 \
         WM-SPEC-020-R08 WM-SPEC-022-R06 WM-SPEC-022-R08 WM-SPEC-022-R09 \
         WM-SPEC-028-R02 WM-SPEC-028-R03; do
  grep -q "$r" .agent/node-contracts/EP-033.md \
    || fail "owned requirement $r missing from contract"
  grep -q "$r" .agent/requirements/VALIDATION_MATRIX.tsv \
    || fail "owned requirement $r missing from validation matrix"
done

grep -q "EP-033" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "EP-033 missing from validation matrix"

echo "contract EP-033 boundaries-and-ownership: ok"
