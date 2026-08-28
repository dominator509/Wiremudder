#!/usr/bin/env sh
# EP-029 M1 contract test: the four authorized new boundaries are declared
# in the node contract, and the owned features and requirements are bound to
# this node before any product implementation.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Authorized new boundaries.
for b in "wirecore/crates/wire-bug-automation/" \
         "tools/wiremudder-bug-lab/" \
         "schemas/wiremudder/bugs/" \
         "maintenance/wiremudder/"; do
  grep -qF "$b" .agent/node-contracts/EP-029.md || fail "boundary $b missing from contract"
done

# Owned features.
for f in WM-FEAT-0133 WM-FEAT-0226 WM-FEAT-0228 WM-FEAT-0229; do
  grep -qF "$f" .agent/node-contracts/EP-029.md || fail "owned feature $f missing from contract"
  grep -qF "$f" .agent/features/FEATURES.tsv || fail "owned feature $f missing from FEATURES.tsv"
done

# Owned requirements.
for r in WM-SPEC-019-R09 WM-SPEC-025-R03; do
  grep -qF "$r" .agent/node-contracts/EP-029.md || fail "owned requirement $r missing from contract"
  grep -qF "$r" .agent/requirements/VALIDATION_MATRIX.tsv || fail "owned requirement $r missing from VALIDATION_MATRIX.tsv"
done

# Live-fire proof is declared by the contract.
grep -q "LF-029" .agent/node-contracts/EP-029.md || fail "LF-029 missing from contract"
grep -q "tests/live-fire/LF-029-bug-remediation-replay.sh" .agent/node-contracts/EP-029.md \
  || fail "LF-029 path missing from contract"

echo "contract EP-029 boundaries-and-ownership: ok"
