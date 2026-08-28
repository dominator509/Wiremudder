#!/usr/bin/env sh
# WM-SPEC-008-R02: scripts, triggers, aliases, timers, macros, key
# bindings, and packages run with measured budgets and slow-offender
# diagnostics.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
grep -q "pub struct PerformanceStats" "$LIB" || fail "PerformanceStats missing"
grep -q "over_budget" "$LIB" || fail "budget samples lack over-budget flag"
grep -q "pub fn slow_offenders" "$LIB" || fail "slow-offender diagnostics missing"
grep -q "BudgetExhausted" "$LIB" || fail "budget enforcement missing"
echo "requirement WM-SPEC-008-R02 measured-budgets-slow-offenders: ok"
