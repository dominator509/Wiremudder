#!/usr/bin/env sh
# EP-026 M1 contract test: soundscape boundaries must be declared in
# the accepted contract before implementation. Fails when an authorized
# boundary, owned feature, or owned requirement is absent from the node
# contract or static fence, or when the live-fire proof is not specified.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Authorized boundaries must appear in the node contract and static fence.
for b in wirecore/crates/wire-soundscape/ src/wiremudder/ui/soundscape/ \
         schemas/wiremudder/audio/ assets/wiremudder/audio/; do
  grep -q "$b" .agent/node-contracts/EP-026.md || fail "authorized boundary $b missing from EP-026 contract"
  grep -q "$b" .agent/expected-files/EP-026.txt || fail "boundary $b missing from static fence"
done

# Owned features must appear in the contract.
for f in WM-FEAT-0075 WM-FEAT-0076; do
  grep -q "$f" .agent/node-contracts/EP-026.md || fail "owned $f missing from EP-026 contract"
done

# Owned requirements must appear in the contract.
grep -q "WM-SPEC-016-R08" .agent/node-contracts/EP-026.md || fail "WM-SPEC-016-R08 missing from EP-026 contract"

# The live-fire proof must be specified.
grep -q "LF-026" .agent/node-contracts/EP-026.md || fail "LF-026 missing from EP-026 contract"
grep -q "tests/live-fire/LF-026-soundscape-degradation.sh" .agent/expected-files/EP-026.txt \
  || fail "LF-026 path missing from static fence"

echo "contract EP-026 soundscape-boundaries: ok"
