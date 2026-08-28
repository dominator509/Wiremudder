#!/usr/bin/env sh
# EP-023 M1 contract test: headless boundaries must be declared in the
# accepted contract before implementation. Fails when an authorized
# boundary, owned feature, or owned requirement is absent from the node
# contract or static fence, or when the live-fire proof is not specified.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

CONTRACT=.agent/node-contracts/EP-023.md
FENCE=.agent/expected-files/EP-023.txt

# Authorized new boundaries declared in the contract and static fence.
for c in src/wiremudder/headless/ wirecore/crates/wire-headless/ schemas/wiremudder/headless/ tools/wiremudder-supervisor/; do
  grep -q "$c" "$CONTRACT" || fail "authorized boundary $c missing from contract"
  grep -q "$c" "$FENCE" || fail "authorized boundary $c missing from static fence"
done

# Live-fire proof specified.
grep -q "LF-023" "$CONTRACT" || fail "LF-023 missing from contract"

# Owned features must be recorded in the node contract.
for f in WM-FEAT-0078 WM-FEAT-0081 WM-FEAT-0083 WM-FEAT-0121 WM-FEAT-0122 WM-FEAT-0123 WM-FEAT-0124 WM-FEAT-0125; do
  grep -q "$f" "$CONTRACT" || fail "owned $f missing from contract"
done

# Owned requirements must be recorded in the node contract.
for r in WM-SPEC-006-R10 WM-SPEC-017-R02 WM-SPEC-017-R04 WM-SPEC-017-R06 WM-SPEC-017-R10 WM-SPEC-024-R04 WM-SPEC-024-R08 WM-SPEC-026-R01; do
  grep -q "$r" "$CONTRACT" || fail "owned $r missing from contract"
done

echo "contract EP-023 headless-boundaries: ok"
