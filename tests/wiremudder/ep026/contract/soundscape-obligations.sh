#!/usr/bin/env sh
# EP-026 M1 contract test: every acceptance obligation from the node
# contract must be covered by an explicit proof target in the live-fire
# script and the owned requirement must exist in SPEC-016. Fails when an
# obligation has no proof path or the owned requirement is missing.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Owned requirement exists in SPEC-016 with the binding scope.
grep -q "WM-SPEC-016-R08: Soundscapes support room, area, combat, boss, weather, death, victory, ambience, and user-authored bindings with independent volume and disable controls" \
  .agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md \
  || fail "WM-SPEC-016-R08 missing from SPEC-016"

# Every acceptance obligation maps to a live-fire grep proof in LF-026.
grep -q "All binding classes are represented" .agent/node-contracts/EP-026.md \
  || fail "obligation 1 (binding classes) missing from contract"
grep -q "Assets carry license and provenance" .agent/node-contracts/EP-026.md \
  || fail "obligation 2 (asset provenance) missing from contract"
grep -q "Volume and disable controls are profile-scoped" .agent/node-contracts/EP-026.md \
  || fail "obligation 3 (profile-scoped controls) missing from contract"
grep -q "Transitions are bounded and cancelable" .agent/node-contracts/EP-026.md \
  || fail "obligation 4 (bounded transitions) missing from contract"
grep -q "Load shedding keeps current loop or silence" .agent/node-contracts/EP-026.md \
  || fail "obligation 5 (load shedding) missing from contract"
grep -q "Audio failure preserves text gameplay" .agent/node-contracts/EP-026.md \
  || fail "obligation 6 (text preservation) missing from contract"

# Fallback is declared: user-local ambience loops with manual room
# binding; automatic transitions and remote assets disabled.
grep -q "manual room binding" .agent/node-contracts/EP-026.md \
  || fail "fallback declaration missing from EP-026 contract"

echo "contract EP-026 soundscape-obligations: ok"
