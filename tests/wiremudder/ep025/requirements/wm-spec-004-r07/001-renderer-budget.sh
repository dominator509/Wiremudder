#!/usr/bin/env sh
# WM-SPEC-004-R07: renderer frame has declared time, memory, and
# cancellation budget.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "FRAME_BUDGET_US" "$LIB" || fail "frame budget constant missing"
grep -q "pub fn render_frame" "$LIB" || fail "frame renderer missing"
grep -q "MAX_EMIT_QUEUE" "$LIB" || fail "queue memory bound missing"
grep -q "emergency_stop" "$LIB" || fail "cancellation missing"
echo "requirement WM-SPEC-004-R07 renderer-budget: ok"
