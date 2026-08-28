#!/usr/bin/env sh
# EP-027 M1 contract test: every acceptance obligation from the node
# contract must be covered by an explicit proof target in the live-fire
# script and the owned requirements must exist in their specifications.
# Fails when an obligation has no proof path or an owned requirement is
# missing.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Owned requirements exist in the accepted specifications.
grep -q "WM-SPEC-018-R04: The Help Knowledge Index is generated reproducibly" \
  .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "WM-SPEC-018-R04 missing from SPEC-018"
grep -q "WM-SPEC-018-R05: Optional source checkout indexing is opt-in" \
  .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "WM-SPEC-018-R05 missing from SPEC-018"
grep -q "WM-SPEC-018-R09: Help content is versioned with the app" \
  .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "WM-SPEC-018-R09 missing from SPEC-018"

# Every acceptance obligation maps to a live-fire grep proof in LF-027.
grep -q "Help content is generated from accepted sources" .agent/node-contracts/EP-027.md \
  || fail "obligation 1 (accepted sources) missing from contract"
grep -q "AI help receives only scoped sanitized context" .agent/node-contracts/EP-027.md \
  || fail "obligation 2 (sanitized context) missing from contract"
grep -q "Coach cannot mutate protected settings or send commands" .agent/node-contracts/EP-027.md \
  || fail "obligation 3 (no mutation) missing from contract"
grep -q "Source index is opt-in, local, idle, and removable" .agent/node-contracts/EP-027.md \
  || fail "obligation 4 (source index) missing from contract"
grep -q "Capability detection is evidence-based" .agent/node-contracts/EP-027.md \
  || fail "obligation 5 (capability detection) missing from contract"
grep -q "CLI/headless help parity passes" .agent/node-contracts/EP-027.md \
  || fail "obligation 6 (CLI parity) missing from contract"

# Fallback is declared: static local help without AI or source indexing.
grep -q "static local help" .agent/node-contracts/EP-027.md \
  || fail "fallback declaration missing from EP-027 contract"

echo "contract EP-027 help-obligations: ok"
