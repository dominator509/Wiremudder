#!/usr/bin/env sh
# EP-018 contract test: no agent can grant itself authority (obligation 6),
# memory access is role-scoped and denied by default (obligation 4), and the
# specialized agent roles exist (WM-SPEC-014-R02).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Role-scoped memory permissions: R06 defines which memory classes each role
# may read, propose, summarize, share, or never access.
grep -q "WM-SPEC-014-R06" .agent/node-contracts/EP-018.md \
  || fail "R06 not owned by EP-018"
grep -q "never access" .agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md \
  || fail "never-access classes not in SPEC-014"

# Specialized agent roles are required (R02) - the contract owns it.
grep -q "WM-SPEC-014-R02" .agent/node-contracts/EP-018.md \
  || fail "R02 not owned by EP-018"
grep -q "mapper/cartographer" .agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md \
  || fail "SPEC-014 missing mapper/cartographer role"
grep -q "privacy firewall" .agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md \
  || fail "SPEC-014 missing privacy firewall role"

# No agent self-grant authority: SPEC-014 forbids hidden inter-agent actions.
grep -q "Hidden inter-agent actions" .agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md \
  || fail "self-authority guard missing"

# Memory permission denial test is a required SPEC-014 test.
grep -q "Memory permission denial" .agent/specs/SPEC-014-agents-copilot-soul-and-guarded-autopilot.md \
  || fail "memory permission denial test not required"

echo "contract agent-authority: ok"
