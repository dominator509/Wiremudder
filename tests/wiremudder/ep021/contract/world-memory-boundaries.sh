#!/usr/bin/env sh
# EP-021 M1 contract test: world-memory boundaries must be declared in
# the accepted contract before implementation. Fails when an authorized
# crate boundary, schema boundary, owned feature, or owned requirement is
# absent from the node contract, or when the live-fire proof is not
# specified.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

CONTRACT=.agent/node-contracts/EP-021.md
FENCE=.agent/expected-files/EP-021.txt

# Authorized new boundaries declared in the contract.
for c in wirecore/crates/wire-world-brain/ wirecore/crates/wire-world-bible/ wirecore/crates/wire-time-machine/ schemas/wiremudder/memory/; do
  grep -q "$c" "$CONTRACT" || fail "authorized boundary $c missing from contract"
  grep -q "$c" "$FENCE" || fail "authorized boundary $c missing from static fence"
done

# Live-fire proof specified.
grep -q "LF-021" "$CONTRACT" || fail "LF-021 missing from contract"

# Owned features and requirements must be recorded in the node contract.
for f in WM-FEAT-0050 WM-FEAT-0051 WM-FEAT-0052 WM-FEAT-0053 WM-FEAT-0191 WM-FEAT-0192 WM-FEAT-0193 WM-FEAT-0194 WM-FEAT-0195; do
  grep -q "$f" "$CONTRACT" || fail "owned $f missing from contract"
done
for r in WM-SPEC-012-R01 WM-SPEC-012-R08 WM-SPEC-012-R09 WM-SPEC-016-R02 WM-SPEC-016-R04 WM-SPEC-016-R07 WM-SPEC-023-R02; do
  grep -q "$r" "$CONTRACT" || fail "owned $r missing from contract"
done

echo "contract EP-021 world-memory-boundaries: ok"
