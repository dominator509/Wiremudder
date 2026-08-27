#!/usr/bin/env sh
# EP-013 M4 failure test: cancellation and route budget.
# A graph larger than the node budget must produce the typed
# BudgetExceeded error, not hang or panic (SPEC-004 bounded work).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

[ -x /root/.cargo/bin/cargo ] || fail "cargo missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example budget_matrix > /tmp/wm-ep013-m4-budget.txt 2>/dev/null \
  || fail "budget matrix"

grep -q "budget-exceeded:ok" /tmp/wm-ep013-m4-budget.txt \
  || fail "route budget not enforced"
grep -q "cancel-safe:ok" /tmp/wm-ep013-m4-budget.txt \
  || fail "cancellation not safe"

echo "failure EP-013 M4 budget-cancellation: ok"
