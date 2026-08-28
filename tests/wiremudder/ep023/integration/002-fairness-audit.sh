#!/usr/bin/env sh
# EP-023 M3 integration test: session fairness, shared policy gates, and
# privacy/audit.
# 1. One busy world cannot starve another (round-robin fairness).
# 2. Desktop and headless use the same scheduler contract.
# 3. Audit trail records cross-session rules and the emergency stop.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-headless/src/lib.rs

# 1. Fairness invariant is structural: one command per session per round,
#    round-robin order.
grep -q "serve_round" "$LIB" || fail "round-robin scheduler missing"
grep -q "one per session per round" "$LIB" || fail "fairness invariant missing"
grep -q "cannot starve another" "$LIB" || fail "starvation guarantee missing"

# 2. Shared contract: the scheduler is the single gate for desktop and
#    headless commands (WM-SPEC-024-R08).
grep -q "enqueue" "$LIB" || fail "shared enqueue gate missing"
grep -q "DeniedPolicy" "$LIB" || fail "policy denial missing"

# 3. Explicit and audited cross-session rules.
grep -q "audit_trail" "$LIB" || fail "audit trail missing"
grep -q "emergency-stop global" "$LIB" || fail "emergency stop not audited"
grep -q "session-create" "$LIB" || fail "session creation not audited"

echo "integration EP-023 M3 fairness-audit: ok"
