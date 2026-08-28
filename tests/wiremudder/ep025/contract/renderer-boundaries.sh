#!/usr/bin/env sh
# EP-025 M1 contract test: renderer boundaries must be declared in the
# accepted contract before implementation. Fails when an authorized
# boundary, owned feature, or owned requirement is absent from the node
# contract or static fence, or when the live-fire proof is not specified.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

CONTRACT=.agent/node-contracts/EP-025.md
FENCE=.agent/expected-files/EP-025.txt

# Authorized new boundaries declared in the contract and static fence.
for c in src/wiremudder/ui/renderer/ wirecore/crates/wire-renderer/ schemas/wiremudder/renderer/ assets/wiremudder/renderer/; do
  grep -q "$c" "$CONTRACT" || fail "authorized boundary $c missing from contract"
  grep -q "$c" "$FENCE" || fail "authorized boundary $c missing from static fence"
done

# Live-fire proof specified.
grep -q "LF-025" "$CONTRACT" || fail "LF-025 missing from contract"

# Owned features must be recorded in the node contract.
for f in WM-FEAT-0069 WM-FEAT-0070 WM-FEAT-0071 WM-FEAT-0072 WM-FEAT-0073 \
         WM-FEAT-0074 WM-FEAT-0077 WM-FEAT-0185 WM-FEAT-0207 WM-FEAT-0208 \
         WM-FEAT-0209 WM-FEAT-0210; do
  grep -q "$f" "$CONTRACT" || fail "owned $f missing from contract"
done

# Owned requirements must be recorded in the node contract.
for r in WM-SPEC-004-R04 WM-SPEC-004-R07 WM-SPEC-016-R01 WM-SPEC-016-R03 \
         WM-SPEC-016-R05 WM-SPEC-016-R06 WM-SPEC-016-R09 WM-SPEC-016-R10; do
  grep -q "$r" "$CONTRACT" || fail "owned $r missing from contract"
done

echo "contract EP-025 renderer-boundaries: ok"
