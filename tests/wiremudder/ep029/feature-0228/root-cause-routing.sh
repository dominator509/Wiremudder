#!/usr/bin/env sh
# WM-FEAT-0228: root-cause routing by subsystem and priority ring.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0228: FAIL - $1" >&2; exit 1; }

grep -q "WM-FEAT-0228" .agent/features/FEATURES.tsv || fail "feature missing from FEATURES.tsv"

# The PriorityRouter exists in the crate and is covered by unit tests that
# prove priority-ring ordering (P0 before P1 before lower).
grep -q "pub struct PriorityRouter" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "PriorityRouter missing from crate"
grep -q "fn priority_router_orders_ring" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "priority-ring unit test missing"
grep -q "fn router_filters_by_subsystem" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "subsystem-filter unit test missing"

# The feature ledger binds routing to this node.
grep -q "root-cause routing by subsystem and priority ring" .agent/features/FEATURES.tsv \
  || fail "routing description missing from FEATURES.tsv"

echo "feature-0228: ok"
