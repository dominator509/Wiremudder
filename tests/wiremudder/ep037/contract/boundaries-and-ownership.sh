#!/usr/bin/env sh
# EP-037 M1 contract test: authorized boundaries and owned features are
# declared in the node contract and traces exactly as the graph requires.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-037.md ] || fail "missing node contract"

for b in docs/wiremudder/user/ docs/wiremudder/developer/ \
         docs/wiremudder/package-author/ examples/wiremudder/; do
  grep -q "$b" .agent/node-contracts/EP-037.md \
    || fail "authorized boundary $b missing from contract"
done

for f in WM-FEAT-0164 WM-FEAT-0243; do
  grep -q "$f" .agent/features/FEATURES.tsv \
    || fail "owned feature $f missing from feature catalog"
  grep -q "$f" .agent/node-contracts/EP-037.md \
    || fail "owned feature $f missing from contract"
done

grep -q "LF-037" .agent/live-fire/PROOFS.tsv \
  || fail "LF-037 missing from live-fire proofs"

echo "contract EP-037 boundaries-and-ownership: ok"
