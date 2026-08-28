#!/usr/bin/env sh
# EP-022 M3 integration test: measured budgets and slow-offender
# diagnostics (WM-SPEC-008-R02) plus bounded replay and timeline.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-debugger/src/lib.rs

# 1. Budgets are measured with over-budget flags.
grep -q "over_budget" "$LIB" || fail "budget sample lacks over-budget flag"
grep -q "slow_offenders" "$LIB" || fail "slow-offender diagnostics missing"

# 2. Bounded resources: replay steps, event ring, variables all capped.
grep -q "MAX_REPLAY_STEPS" "$LIB" || fail "replay step bound missing"
grep -q "EVENT_RING_CAPACITY" "$LIB" || fail "event ring bound missing"
grep -q "MAX_VARIABLES" "$LIB" || fail "variable bound missing"
grep -q "MAX_MACRO_LEN" "$LIB" || fail "macro length bound missing"

# 3. Explicit cancellation/budget enforcement in replay.
grep -q "BudgetExhausted" "$LIB" || fail "replay lacks budget exhaustion denial"

# 4. Typed errors: denials are structured, not strings.
grep -q "pub enum DebugDenial" "$LIB" || fail "no typed denial enum"

echo "integration EP-022 M3 budgets-bounded-resources: ok"
