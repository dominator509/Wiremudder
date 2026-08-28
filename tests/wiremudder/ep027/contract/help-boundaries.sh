#!/usr/bin/env sh
# EP-027 M1 contract test: help boundaries must be declared in the
# accepted contract before implementation. Fails when an authorized
# boundary, owned feature, or owned requirement is absent from the node
# contract or static fence, or when the live-fire proof is not specified.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Authorized boundaries must appear in the node contract and static fence.
for b in src/wiremudder/ui/help/ wirecore/crates/wire-help/ \
         schemas/wiremudder/help/ tools/help-indexer/; do
  grep -q "$b" .agent/node-contracts/EP-027.md || fail "authorized boundary $b missing from EP-027 contract"
  grep -q "$b" .agent/expected-files/EP-027.txt || fail "boundary $b missing from static fence"
done

# Owned features must appear in the contract.
for f in WM-FEAT-0109 WM-FEAT-0111 WM-FEAT-0112 WM-FEAT-0187 WM-FEAT-0213 \
         WM-FEAT-0214 WM-FEAT-0215 WM-FEAT-0216 WM-FEAT-0217 WM-FEAT-0218 \
         WM-FEAT-0219; do
  grep -q "$f" .agent/node-contracts/EP-027.md || fail "owned $f missing from EP-027 contract"
done

# Owned requirements must appear in the contract.
for r in WM-SPEC-007-R09 WM-SPEC-018-R04 WM-SPEC-018-R05 WM-SPEC-018-R09; do
  grep -q "$r" .agent/node-contracts/EP-027.md || fail "owned $r missing from EP-027 contract"
done

# The live-fire proof must be specified.
grep -q "LF-027" .agent/node-contracts/EP-027.md || fail "LF-027 missing from EP-027 contract"
grep -q "tests/live-fire/LF-027-help-coach-no-side-effects.sh" .agent/expected-files/EP-027.txt \
  || fail "LF-027 path missing from static fence"

echo "contract EP-027 help-boundaries: ok"
