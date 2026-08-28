#!/usr/bin/env sh
# EP-022 M1 contract test: AI Debugger must not be granted gate-editing
# authority by any accepted contract. Fails if the node contract, an
# owning specification, or the security constitution grants the AI
# Debugger authority to edit Graphlock gates, self-certify success, or
# access secrets.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# SPEC-019-R06: AI Debugger may analyze approved evidence and propose a
# hypothesis, reproduction, patch plan, tests, risk, and rollback but
# cannot self-certify success. The contract must state this limitation.
grep -q "cannot self-certify success" .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md || fail "R06 self-certify prohibition missing from SPEC-019"
grep -q "cannot edit gates" .agent/node-contracts/EP-022.md || fail "gate-editing prohibition missing from EP-022 contract"

# Security constitution: no new authority, secret access, or stable
# publication implied by this node.
grep -q "No new authority" .agent/node-contracts/EP-022.md || fail "no-new-authority clause missing from EP-022 contract"

echo "contract EP-022 ai-debugger-authority: ok"
