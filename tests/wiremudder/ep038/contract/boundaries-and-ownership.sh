#!/usr/bin/env sh
# EP-038 M1 contract test: authorized boundaries and owned features/
# requirements are declared in the node contract and traces exactly as the
# graph requires.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-038.md ] || fail "missing node contract"

for b in release/wiremudder/candidate/ .agent/state/release-evidence/ \
         docs/wiremudder/release-candidate/; do
  grep -q "$b" .agent/node-contracts/EP-038.md \
    || fail "authorized boundary $b missing from contract"
done

grep -q "WM-FEAT-0244" .agent/features/FEATURES.tsv \
  || fail "WM-FEAT-0244 missing from feature catalog"
grep -q "WM-FEAT-0244" .agent/node-contracts/EP-038.md \
  || fail "WM-FEAT-0244 missing from contract"

for r in WM-SPEC-000-R01 WM-SPEC-000-R09 WM-SPEC-000-R10 WM-SPEC-028-R01; do
  grep -q "$r" .agent/requirements/VALIDATION_MATRIX.tsv \
    || fail "owned requirement $r missing from validation matrix"
  grep -q "$r" .agent/node-contracts/EP-038.md \
    || fail "owned requirement $r missing from contract"
done

grep -q "LF-038" .agent/live-fire/PROOFS.tsv \
  || fail "LF-038 missing from live-fire proofs"

echo "contract EP-038 boundaries-and-ownership: ok"
