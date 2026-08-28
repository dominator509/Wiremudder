#!/usr/bin/env sh
# EP-029 M1 contract test: the six acceptance obligations of the node
# contract must be declared as binding requirements before product work:
# 1. Automation requires reproduction or evidence-backed explanation.
# 2. Patches stay subsystem-scoped.
# 3. Independent tests and review are required.
# 4. No security, privacy, performance, or Graphlock gate can be weakened.
# 5. Retries are bounded and signatures tracked.
# 6. Failure reaches a complete BLOCKED report.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Obligations must be stated in the node contract.
for ob in "Automation requires reproduction or evidence-backed explanation" \
          "Patches stay subsystem-scoped" \
          "Independent tests and review are required" \
          "No security, privacy, performance, or Graphlock gate can be weakened" \
          "Retries are bounded and signatures tracked" \
          "Failure reaches a complete BLOCKED report"; do
  grep -qF "$ob" .agent/node-contracts/EP-029.md || fail "obligation missing from EP-029 contract: $ob"
done

# Bug automation uses bounded reproduction, diagnosis, patch, test, review,
# canary, and rollback states and reaches DONE or evidence-backed BLOCKED
# (WM-SPEC-019-R09).
grep -q "WM-SPEC-019-R09: Bug automation uses bounded reproduction, diagnosis, patch, test, review, canary, and rollback states and reaches DONE or evidence-backed BLOCKED" \
  .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md \
  || fail "bounded-remediation rule missing from SPEC-019"

# Retries are bounded, jittered where network-appropriate, idempotent, and
# never applied to destructive or ambiguous effects without an idempotency key
# (WM-SPEC-025-R03).
grep -q "WM-SPEC-025-R03: Retries are bounded, jittered where network-appropriate, idempotent, and never applied to destructive or ambiguous effects without an idempotency key" \
  .agent/specs/SPEC-025-error-handling-recovery-and-compensation.md \
  || fail "bounded-retry rule missing from SPEC-025"

# AI Debugger may propose but cannot self-certify success (WM-SPEC-019-R06).
grep -q "WM-SPEC-019-R06: AI Debugger may analyze approved evidence and propose a hypothesis, reproduction, patch plan, tests, risk, and rollback but cannot self-certify success" \
  .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md \
  || fail "no-self-certify rule missing from SPEC-019"

# Security-sensitive changes require forced-failure and denial tests and
# cannot be waived by a model vote (WM-SPEC-022-R09).
grep -q "WM-SPEC-022-R09: Security-sensitive changes require forced-failure and denial tests and cannot be waived by a model vote" \
  .agent/specs/SPEC-022-security-privacy-threat-model-and-abuse-boundaries.md \
  || fail "forced-failure rule missing from SPEC-022"

echo "contract EP-029 bug-automation-obligations: ok"
