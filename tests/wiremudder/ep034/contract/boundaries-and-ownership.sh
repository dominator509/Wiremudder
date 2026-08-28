#!/usr/bin/env sh
# EP-034 M1 contract test: authorized boundaries and owned requirements are
# declared in the node contract and traces exactly as the graph requires.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-034.md ] || fail "missing node contract"

for b in src/wiremudder/updater/ wirecore/crates/wire-updater/ \
         schemas/wiremudder/update/ tools/update-fixtures/; do
  grep -q "$b" .agent/node-contracts/EP-034.md \
    || fail "authorized boundary $b missing from contract"
done

for r in WM-SPEC-020-R04 WM-SPEC-020-R06 WM-SPEC-020-R10 \
         WM-SPEC-028-R04 WM-SPEC-028-R08; do
  grep -q "$r" .agent/node-contracts/EP-034.md \
    || fail "owned requirement $r missing from contract"
  grep -q "$r" .agent/requirements/VALIDATION_MATRIX.tsv \
    || fail "owned requirement $r missing from validation matrix"
done

grep -q "EP-034" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "EP-034 missing from validation matrix"

# The eleven owned features must be present in the feature catalog.
for f in WM-FEAT-0102 WM-FEAT-0230 WM-FEAT-0231 WM-FEAT-0232 WM-FEAT-0233 \
         WM-FEAT-0234 WM-FEAT-0235 WM-FEAT-0236 WM-FEAT-0237 WM-FEAT-0238 \
         WM-FEAT-0240; do
  grep -q "$f" .agent/features/FEATURES.tsv \
    || fail "owned feature $f missing from feature catalog"
  grep -q "$f" .agent/node-contracts/EP-034.md \
    || fail "owned feature $f missing from contract"
done

echo "contract EP-034 boundaries-and-ownership: ok"
