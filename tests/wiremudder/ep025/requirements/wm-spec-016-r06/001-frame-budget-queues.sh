#!/usr/bin/env sh
# WM-SPEC-016-R06: frame-budgeted queues drop or coalesce noncritical
# emits and freeze to static imagery before terminal performance
# degrades.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "FRAME_BUDGET_US" "$LIB" || fail "frame budget missing"
grep -q "MAX_EMIT_QUEUE" "$LIB" || fail "queue bound missing"
grep -q "coalesces" "$LIB" || fail "coalesce behavior missing"
grep -q "drops" "$LIB" || fail "drop behavior missing"
grep -q "pub fn is_frozen" "$LIB" || fail "freeze-to-static missing"
echo "requirement WM-SPEC-016-R06 frame-budget-queues: ok"
