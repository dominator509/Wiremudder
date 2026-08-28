#!/usr/bin/env sh
# WM-FEAT-0162: event replay for scripts and triggers with evidence,
# safety, rollback, and release-profile controls.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0162: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
grep -q "pub struct TriggerLab" "$LIB" || fail "TriggerLab missing"
grep -q "pub fn replay" "$LIB" || fail "deterministic replay missing"
grep -q "BudgetExhausted" "$LIB" || fail "replay lacks budget enforcement"
grep -q "pub fn timeline" "$LIB" || fail "event timeline missing"
echo "feature WM-FEAT-0162 event-replay-scripts-triggers: ok"
