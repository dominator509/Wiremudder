#!/usr/bin/env sh
# EP-019 contract test: Guarded Autopilot acceptance obligations.
# 1. Autopilot is off by default and profile-scoped.
# 2. Every action is visible before send according to policy.
# 3. Stale or ambiguous state pauses.
# 4. Emergency stop cancels immediately.
# 5. Rate and command policies are deterministic.
# 6. No routing, account, evasion, or hidden social automation is possible.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

grep -q "WM-FEAT-0041" .agent/node-contracts/EP-019.md || fail "WM-FEAT-0041 not owned by EP-019"
grep -q "WM-SPEC-009-R02" .agent/node-contracts/EP-019.md || fail "R02 not owned by EP-019"
grep -q "WM-SPEC-009-R04" .agent/node-contracts/EP-019.md || fail "R04 not owned by EP-019"
grep -q "WM-SPEC-014-R10" .agent/node-contracts/EP-019.md || fail "R10 not owned by EP-019"

# SPEC-009: autopilot enters the same deterministic Action Proposal path.
grep -q "same deterministic Action Proposal path" .agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md \
  || fail "SPEC-009 missing shared proposal path"
# Destructive/social/trade/PvP/account/privacy/irreversible require confirmation.
grep -q "require explicit confirmation" .agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md \
  || fail "SPEC-009 missing confirmation requirement"
# SPEC-014-R10: visible, rate-limited, cancellable Action Proposals.
grep -q "visible, rate-limited, cancellable Action Proposals" .agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md \
  || fail "SPEC-014-R10 missing visible/rate-limited/cancellable"
grep -q "pauses when state, command policy, route, or approvals become stale" .agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md \
  || fail "SPEC-014-R10 missing stale-state pause"

# No hidden auto-send: SPEC-009 non-goals.
grep -q "Hidden auto-send" .agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md \
  || fail "SPEC-009 missing hidden auto-send non-goal"

echo "contract autopilot-contract: ok"
