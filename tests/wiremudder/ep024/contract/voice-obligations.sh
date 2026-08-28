#!/usr/bin/env sh
# EP-024 M1 contract test: every acceptance obligation of the node
# contract must be satisfied by an owning specification or security
# constitution. Fails if an obligation has no binding source.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

CONTRACT=.agent/node-contracts/EP-024.md
SPEC015=.agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md
SPEC009=.agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md
SPEC010=.agent/specs/SPEC-010-profiles-privacy-consent-secrets-and-routing-defaults.md

# Acceptance obligation 1: Mic state is always visible.
grep -q "microphone state is always visible" "$SPEC015" || fail "obligation 1 (mic state) has no source"
# Obligation 2: Push-to-talk works with a real certified provider path.
grep -q "Push-to-talk and hold-to-talk are the initial activation modes" "$SPEC015" || fail "obligation 2 (push-to-talk) has no source"
# Obligation 3: Remote speech obeys privacy and consent.
grep -q "remote speech requires configured provider, privacy policy, redaction, and consent" "$SPEC015" || fail "obligation 3 (remote privacy) has no source"
# Obligation 4: Voice commands pass command safety.
grep -q "voice" "$SPEC009" || fail "obligation 4 (command safety) has no source"
# Obligation 5: Barge-in cancels.
grep -q "Barge-in cancels" "$SPEC015" || fail "obligation 5 (barge-in) has no source"
# Obligation 6: Worker crash and load shed to text.
grep -q "degrades to text" "$SPEC015" || fail "obligation 6 (degrade to text) has no source"

echo "contract EP-024 voice-obligations: ok"
