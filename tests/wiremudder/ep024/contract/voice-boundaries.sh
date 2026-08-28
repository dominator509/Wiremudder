#!/usr/bin/env sh
# EP-024 M1 contract test: voice boundaries must be declared in the
# accepted contract before implementation. Fails when an authorized
# boundary, owned feature, or owned requirement is absent from the node
# contract or static fence, or when the live-fire proof is not specified.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

CONTRACT=.agent/node-contracts/EP-024.md
FENCE=.agent/expected-files/EP-024.txt

# Authorized new boundaries declared in the contract and static fence.
for c in wirecore/crates/wire-voice/ src/wiremudder/ui/voice/ schemas/wiremudder/voice/ config/wiremudder/voice/; do
  grep -q "$c" "$CONTRACT" || fail "authorized boundary $c missing from contract"
  grep -q "$c" "$FENCE" || fail "authorized boundary $c missing from static fence"
done

# Live-fire proof specified.
grep -q "LF-024" "$CONTRACT" || fail "LF-024 missing from contract"

# Owned features must be recorded in the node contract.
for f in WM-FEAT-0057 WM-FEAT-0058 WM-FEAT-0059 WM-FEAT-0060 WM-FEAT-0061 \
         WM-FEAT-0062 WM-FEAT-0063 WM-FEAT-0064 WM-FEAT-0065 WM-FEAT-0066 \
         WM-FEAT-0067 WM-FEAT-0068 WM-FEAT-0186 WM-FEAT-0211 WM-FEAT-0212; do
  grep -q "$f" "$CONTRACT" || fail "owned $f missing from contract"
done

# Owned requirements must be recorded in the node contract.
for r in WM-SPEC-007-R02 WM-SPEC-010-R08 WM-SPEC-015-R07 WM-SPEC-015-R10; do
  grep -q "$r" "$CONTRACT" || fail "owned $r missing from contract"
done

echo "contract EP-024 voice-boundaries: ok"
