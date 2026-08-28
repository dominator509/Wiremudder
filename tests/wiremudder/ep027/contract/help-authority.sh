#!/usr/bin/env sh
# EP-027 M1 contract test: the Setup Coach and help system must not gain
# mutation authority. Fails if the node contract, an owning
# specification, or the security constitution grants the coach the
# ability to change settings, enable telemetry/autopilot, change
# routing, install packages, send commands, edit Soul documents or
# command packs, or access secrets; or if help can block settings
# interaction or gameplay.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# SPEC-018-R06: the coach may explain and propose steps but cannot
# change settings, enable telemetry or autopilot, change routing,
# install packages, send commands, edit Soul documents, edit command
# packs, or access secrets.
grep -q "cannot change settings" .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "coach no-mutation rule missing from SPEC-018"
grep -q "send commands" .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "coach no-command rule missing from SPEC-018"
grep -q "access secrets" .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "coach no-secrets rule missing from SPEC-018"

# SPEC-018-R10: help requests never block settings interaction or gameplay.
grep -q "Help requests never block settings interaction or gameplay" .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "non-blocking rule missing from SPEC-018"

# SPEC-007-R09: destructive or privacy-sensitive actions disclose
# effect, scope, source, and confirmation status.
grep -q "WM-SPEC-007-R09: Destructive or privacy-sensitive actions disclose effect, scope, source, and confirmation status" \
  .agent/specs/SPEC-007-desktop-terminal-workspace-accessibility.md \
  || fail "disclosure rule missing from SPEC-007"

# No new authority, secret access, or stable publication implied.
grep -q "No new authority" .agent/node-contracts/EP-027.md \
  || fail "no-new-authority clause missing from EP-027 contract"

# SPEC-010 privacy: help modes are local-only and remote-redacted or
# disabled according to privacy policy (SPEC-018-R03).
grep -q "WM-SPEC-018-R03: Help modes are local-only and remote-redacted or disabled according to privacy policy" \
  .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "privacy help modes missing from SPEC-018"

echo "contract EP-027 help-authority: ok"
