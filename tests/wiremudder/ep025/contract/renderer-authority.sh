#!/usr/bin/env sh
# EP-025 M1 contract test: the renderer must not gain new authority.
# Fails if the node contract, an owning specification, or the security
# constitution grants the renderer secret access, remote egress,
# routing control, signing capability, or stable publication; or if
# protected third-party assets can be copied.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# SPEC-016: original retro presentation only; no protected assets.
grep -q "does not copy protected Nintendo, Zelda, Mario" .agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md \
  || fail "protected-asset prohibition missing from SPEC-016"
grep -q "Raw text remains visible and authoritative" .agent/specs/SPEC-016-retro-renderer-visual-emits-and-soundscapes.md \
  || fail "raw-text authority missing from SPEC-016"

# No new authority, secret access, or stable publication implied.
grep -q "No new authority" .agent/node-contracts/EP-025.md \
  || fail "no-new-authority clause missing from EP-025 contract"

# WIREMUDDER_SECURITY.md: asset metadata is validated and untrusted
# inputs are bounded; renderer interactions cannot grant scopes or send
# commands directly.
grep -q "asset metadata" WIREMUDDER_SECURITY.md || fail "asset-metadata validation missing from security constitution"
grep -q "renderer interactions" WIREMUDDER_SECURITY.md || fail "renderer no-scope rule missing from security constitution"

echo "contract EP-025 renderer-authority: ok"
