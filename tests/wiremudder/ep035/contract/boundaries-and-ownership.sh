#!/usr/bin/env sh
# EP-035 M1 contract test: authorized boundaries and owned requirements are
# declared in the node contract and traces exactly as the graph requires.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-035.md ] || fail "missing node contract"

for b in CI/wiremudder/ installers/wiremudder/ \
         packaging/wiremudder/ docs/wiremudder/release/; do
  grep -q "$b" .agent/node-contracts/EP-035.md \
    || fail "authorized boundary $b missing from contract"
done

for r in WM-SPEC-020-R01 WM-SPEC-020-R09 WM-SPEC-026-R10 \
         WM-SPEC-028-R05 WM-SPEC-028-R07 WM-SPEC-028-R09 WM-SPEC-028-R10; do
  grep -q "$r" .agent/node-contracts/EP-035.md \
    || fail "owned requirement $r missing from contract"
  grep -q "$r" .agent/requirements/VALIDATION_MATRIX.tsv \
    || fail "owned requirement $r missing from validation matrix"
done

grep -q "EP-035" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "EP-035 missing from validation matrix"

for f in WM-FEAT-0239 WM-FEAT-0241; do
  grep -q "$f" .agent/features/FEATURES.tsv \
    || fail "owned feature $f missing from feature catalog"
  grep -q "$f" .agent/node-contracts/EP-035.md \
    || fail "owned feature $f missing from contract"
done

echo "contract EP-035 boundaries-and-ownership: ok"
