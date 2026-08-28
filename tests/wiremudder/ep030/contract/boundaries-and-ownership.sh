#!/usr/bin/env sh
# EP-030 M1 contract test: the four authorized new boundaries are declared
# in the node contract, and the owned feature and requirement are bound to
# this node before any product implementation.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Authorized new boundaries.
for b in "wirecore/crates/wire-import/" \
         "src/wiremudder/ui/import/" \
         "compatibility/imports/" \
         "schemas/wiremudder/import/"; do
  grep -qF "$b" .agent/node-contracts/EP-030.md || fail "boundary $b missing from contract"
done

# Owned feature.
grep -qF "WM-FEAT-0120" .agent/node-contracts/EP-030.md || fail "owned feature missing from contract"
grep -qF "WM-FEAT-0120" .agent/features/FEATURES.tsv || fail "owned feature missing from FEATURES.tsv"

# Owned requirement.
grep -qF "WM-SPEC-020-R07" .agent/node-contracts/EP-030.md || fail "owned requirement missing from contract"
grep -qF "WM-SPEC-020-R07" .agent/requirements/VALIDATION_MATRIX.tsv || fail "owned requirement missing from VALIDATION_MATRIX.tsv"

# Live-fire proof is declared by the contract.
grep -q "LF-030" .agent/node-contracts/EP-030.md || fail "LF-030 missing from contract"
grep -q "tests/live-fire/LF-030-import-migration-disabled-automation.sh" .agent/node-contracts/EP-030.md \
  || fail "LF-030 path missing from contract"

echo "contract EP-030 boundaries-and-ownership: ok"
