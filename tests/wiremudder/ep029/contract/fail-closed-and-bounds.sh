#!/usr/bin/env sh
# EP-029 M1 contract test: fail-closed and bounded-retry semantics are
# anchored in accepted specifications so no later milestone can weaken them.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Unknown errors fail closed for command, privacy, secret, permission,
# routing, update, and signing decisions (WM-SPEC-025-R06).
grep -q "WM-SPEC-025-R06: Unknown errors fail closed for command, privacy, secret, permission, routing, update, and signing decisions" \
  .agent/specs/SPEC-025-error-handling-recovery-and-compensation.md \
  || fail "fail-closed rule missing from SPEC-025"

# Repeated failures quarantine the optional subsystem and preserve text
# gameplay (WM-SPEC-025-R04).
grep -q "WM-SPEC-025-R04: Repeated failures quarantine the optional subsystem or asset and preserve text gameplay" \
  .agent/specs/SPEC-025-error-handling-recovery-and-compensation.md \
  || fail "quarantine rule missing from SPEC-025"

# Partial side effects use compensation or explicit reconciliation and are
# visible in audit history (WM-SPEC-025-R05).
grep -q "WM-SPEC-025-R05: Partial side effects use compensation or explicit reconciliation and are visible in audit history" \
  .agent/specs/SPEC-025-error-handling-recovery-and-compensation.md \
  || fail "compensation rule missing from SPEC-025"

# P0/P1 bugs receive performance review; sensitive-class bugs receive privacy
# or security review (WM-SPEC-019-R10).
grep -q "WM-SPEC-019-R10: Any P0/P1 bug receives performance review and any transcript, AI, voice, routing, secrets, package, or update bug receives privacy or security review" \
  .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md \
  || fail "review-routing rule missing from SPEC-019"

echo "contract EP-029 fail-closed-and-bounds: ok"
