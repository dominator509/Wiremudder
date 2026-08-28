#!/usr/bin/env sh
# EP-024 M1 contract test: the voice companion must not gain new
# authority. Fails if the node contract, an owning specification, or the
# security constitution grants the voice runtime secret access, remote
# egress, routing control, signing capability, or stable publication; or
# if microphone capture can be hidden.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# SPEC-015: voice companion, macros, and accessibility.
grep -q "microphone state is always visible" .agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md \
  || fail "mic visibility missing from SPEC-015"
grep -q "Voice bypass of command safety" .agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md \
  || fail "voice bypass non-goal missing from SPEC-015"
grep -q "Hidden microphone capture" .agent/specs/SPEC-015-voice-companion-macros-and-accessibility.md \
  || fail "hidden capture non-goal missing from SPEC-015"

# No new authority, secret access, or stable publication implied.
grep -q "No new authority" .agent/node-contracts/EP-024.md \
  || fail "no-new-authority clause missing from EP-024 contract"

# WIREMUDDER_SECURITY.md: hidden microphone capture prohibited; voice
# cannot grant scopes or send commands directly.
grep -q "hidden microphone capture" WIREMUDDER_SECURITY.md \
  || fail "hidden mic capture prohibition missing from security constitution"
grep -q "voice" WIREMUDDER_SECURITY.md || fail "voice absent from security constitution"

echo "contract EP-024 voice-authority: ok"
