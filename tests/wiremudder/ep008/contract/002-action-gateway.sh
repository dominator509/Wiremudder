#!/usr/bin/env sh
# Contract test: the action-gateway semantics are declared. One gateway
# for all non-manual sources; deterministic risk/confirmation; no
# high-confidence shortcut; emergency stop within P0 budget; Human-Tempo
# is anti-spam only; every action replayable from audit.
set -eu

cd "$(dirname "$0")/../../../.."

python3 - <<'PY' || { echo "FAIL: action-gateway contract" >&2; exit 1; }
from pathlib import Path
contract = Path('.agent/node-contracts/EP-008.md').read_text(encoding='utf-8')
spec = Path('.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md').read_text(encoding='utf-8')

# 1. One gateway for every non-manual source (WM-SPEC-009-R02).
assert 'AI, autopilot, voice, macro, trigger, script, plugin, headless' in spec, 'R02 sources not bound'

# 2. Deterministic risk and confirmation policy; no high-confidence
#    shortcut (WM-SPEC-009-R05).
assert 'No command is sent solely because a model reports high confidence' in spec, 'R05 not bound'

# 3. Emergency stop cancels queued automation and propagates within the
#    P0 budget (WM-SPEC-009-R06, WM-SPEC-004-R11).
assert 'P0 target budget' in spec, 'R06 budget not bound'
assert 'emergency stop under 10 ms' in Path('.agent/specs/SPEC-004-performance-constitution-and-degradation.md').read_text(), 'R11 budget not bound'

# 4. Human-Tempo is anti-spam, not evasion (WM-SPEC-009-R07).
assert 'not bot-detection evasion' in spec, 'R07 not bound'

# 5. Every action replayable from audit evidence (WM-SPEC-009-R09,
#    acceptance obligation 6).
assert 'traceable to observation' in spec, 'R09 not bound'

# 6. Stale safety state pauses automation (WM-SPEC-009-R10).
assert 'pauses automation rather than guessing' in spec, 'R10 not bound'

# 7. Manual input remains direct (WM-SPEC-009-R01).
assert 'Manual user input remains direct' in spec, 'R01 not bound'

# 8. Prompt injection cannot override the gate (WM-SPEC-022-R04).
assert 'Prompt injection cannot override' in Path('.agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md').read_text(), 'R04 not bound'
print('contract action-gateway: ok')
PY

echo "contract action-gateway: ok"
