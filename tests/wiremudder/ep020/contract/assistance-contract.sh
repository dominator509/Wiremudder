#!/usr/bin/env sh
# EP-020 contract test: Quest Compass, Tactical HUD, Personal Narrator
# acceptance obligations.
# 1. Quest state cites clues and corrections.
# 2. Tactical HUD uses bounded current snapshots.
# 3. Narrator respects privacy and load shedding.
# 4. Uncertainty is visible.
# 5. No feature sends commands by itself.
# 6. Performance remains P2/P3.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

for f in WM-FEAT-0054 WM-FEAT-0055 WM-FEAT-0056 WM-FEAT-0183 WM-FEAT-0184; do
  grep -q "$f" .agent/node-contracts/EP-020.md || fail "$f not owned by EP-020"
done
grep -q "WM-SPEC-012-R06" .agent/node-contracts/EP-020.md || fail "R06 not owned by EP-020"
grep -q "WM-SPEC-012-R07" .agent/node-contracts/EP-020.md || fail "R07 not owned by EP-020"

# SPEC-012-R06: quest compass cites clues and state classes.
grep -q "cites clues and distinguishes observed, inferred, completed, failed, and user-corrected state" \
  .agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md \
  || fail "SPEC-012-R06 missing"
# SPEC-012-R07: tactical HUD bounded + no commands.
grep -q "cannot send commands by itself" \
  .agent/specs/SPEC-012-mapper-world-brain-world-bible-and-memory.md \
  || fail "SPEC-012-R07 missing"
# SPEC-015-R06: narrator discloses source, respects privacy.
grep -q "disclose their source and respect privacy" \
  .agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md \
  || fail "SPEC-015-R06 missing"

echo "contract assistance-contract: ok"
