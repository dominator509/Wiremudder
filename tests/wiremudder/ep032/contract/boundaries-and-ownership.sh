#!/usr/bin/env sh
# EP-032 M1 contract test: authorized boundaries and owned features and
# requirements are declared in the node contract and traces exactly as the
# graph requires.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-032.md ] || fail "missing node contract"

for b in benchmarks/wiremudder/ tests/wiremudder/performance/ \
         docs/wiremudder/performance/ tools/perf-capture/; do
  grep -q "$b" .agent/node-contracts/EP-032.md \
    || fail "authorized boundary $b missing from contract"
done

for f in WM-FEAT-0131 WM-FEAT-0134 WM-FEAT-0135 WM-FEAT-0136 WM-FEAT-0137 \
         WM-FEAT-0138 WM-FEAT-0139 WM-FEAT-0140 WM-FEAT-0141 WM-FEAT-0142 \
         WM-FEAT-0143 WM-FEAT-0144 WM-FEAT-0145 WM-FEAT-0163; do
  grep -q "$f" .agent/node-contracts/EP-032.md \
    || fail "owned feature $f missing from contract"
  grep -q "$f" .agent/features/FEATURES.tsv \
    || fail "owned feature $f missing from FEATURES.tsv"
done

for r in WM-SPEC-002-R07 WM-SPEC-002-R09 WM-SPEC-004-R12 WM-SPEC-019-R10 WM-SPEC-027-R06; do
  grep -q "$r" .agent/node-contracts/EP-032.md \
    || fail "owned requirement $r missing from contract"
  grep -q "$r" .agent/requirements/VALIDATION_MATRIX.tsv \
    || fail "owned requirement $r missing from validation matrix"
done

grep -q "EP-032" .agent/requirements/VALIDATION_MATRIX.tsv \
  || fail "EP-032 missing from validation matrix"

echo "contract EP-032 boundaries-and-ownership: ok"
