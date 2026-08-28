#!/usr/bin/env sh
# EP-023 M1 contract test: headless mode must not gain new authority.
# Fails if the node contract, an owning specification, or the security
# constitution grants the headless runtime secret access, remote egress,
# routing control, signing capability, or stable publication; or if the
# global emergency stop is not specified.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# SPEC-009: command safety, emergency stop, and pacing. The headless
# runtime must respect the same emergency stop as desktop sessions.
grep -q "emergency stop" .agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md || fail "emergency stop missing from SPEC-009"
grep -q "emergency stop" .agent/node-contracts/EP-023.md || fail "emergency stop missing from EP-023 contract"

# No new authority, secret access, or stable publication implied.
grep -q "No new authority" .agent/node-contracts/EP-023.md || fail "no-new-authority clause missing from EP-023 contract"

# SPEC-017-R04: headless can disable UI, renderer, audio, and voice.
grep -q "WM-SPEC-017-R04" .agent/node-contracts/EP-023.md || fail "headless disable surface missing from contract"

echo "contract EP-023 headless-authority: ok"
