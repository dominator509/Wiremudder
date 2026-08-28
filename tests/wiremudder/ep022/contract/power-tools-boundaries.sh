#!/usr/bin/env sh
# EP-022 M1 contract test: power-tools boundaries must be declared in
# the accepted contract before implementation. Fails when an authorized
# crate boundary, schema boundary, UI boundary, compatibility boundary,
# owned feature, or owned requirement is absent from the node contract
# or static fence, or when the live-fire proof is not specified.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

CONTRACT=.agent/node-contracts/EP-022.md
FENCE=.agent/expected-files/EP-022.txt

# Authorized new boundaries declared in the contract and static fence.
for c in src/wiremudder/ui/power-tools/ wirecore/crates/wire-debugger/ compatibility/automation/ schemas/wiremudder/debug/; do
  grep -q "$c" "$CONTRACT" || fail "authorized boundary $c missing from contract"
  grep -q "$c" "$FENCE" || fail "authorized boundary $c missing from static fence"
done

# Live-fire proof specified.
grep -q "LF-022" "$CONTRACT" || fail "LF-022 missing from contract"

# Owned features must be recorded in the node contract.
for f in WM-FEAT-0106 WM-FEAT-0107 WM-FEAT-0108 WM-FEAT-0127 WM-FEAT-0161 WM-FEAT-0162; do
  grep -q "$f" "$CONTRACT" || fail "owned $f missing from contract"
done

# Owned requirements must be recorded in the node contract.
for r in WM-SPEC-008-R02 WM-SPEC-008-R07 WM-SPEC-008-R08 WM-SPEC-019-R06; do
  grep -q "$r" "$CONTRACT" || fail "owned $r missing from contract"
done

echo "contract EP-022 power-tools-boundaries: ok"
