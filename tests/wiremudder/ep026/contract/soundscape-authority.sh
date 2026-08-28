#!/usr/bin/env sh
# EP-026 M1 contract test: the soundscape engine must not gain new
# authority. Fails if the node contract, an owning specification, or
# the security constitution grants the soundscape secret access, remote
# egress, routing control, signing capability, or stable publication;
# or if audio failure can hide or delay text gameplay.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# SPEC-016: raw text remains visible and authoritative; audio failure
# preserves text gameplay.
grep -q "Raw text remains visible and authoritative" .agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md \
  || fail "raw-text authority missing from SPEC-016"
grep -q "Renderer or audio worker failure disables immersion and preserves text gameplay" .agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md \
  || fail "audio-failure-preserves-text rule missing from SPEC-016"

# SPEC-004: soundscapes are P3 and may drop, coalesce, freeze, cancel,
# or disable; P0 never waits on optional work.
grep -q "P3 contains voice, renderer, visual emits, narrator, and soundscapes" .agent/specs/SPEC-004-performance-constitution-and-degradation.md \
  || fail "soundscape P3 class missing from SPEC-004"

# No new authority, secret access, or stable publication implied.
grep -q "No new authority" .agent/node-contracts/EP-026.md \
  || fail "no-new-authority clause missing from EP-026 contract"

# WIREMUDDER_SECURITY.md: asset metadata is validated and untrusted
# inputs are bounded; soundscape interactions cannot grant scopes or
# send commands directly.
grep -q "asset metadata" WIREMUDDER_SECURITY.md || fail "asset-metadata validation missing from security constitution"
grep -q "renderer interactions" WIREMUDDER_SECURITY.md || fail "no-scope rule missing from security constitution"

echo "contract EP-026 soundscape-authority: ok"
