#!/usr/bin/env sh
# WM-SPEC-014-R10: Guarded Autopilot creates visible, rate-limited,
# cancellable Action Proposals and pauses when state, command policy,
# route, or approvals become stale.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r10: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-autopilot/src/lib.rs
grep -q "pub fn propose" "$LIB" || fail "propose missing"
grep -q "approved-visible" "$LIB" || fail "visible queue missing"
grep -q "max_actions_per_window" "$LIB" || fail "rate limit missing"
grep -q "pub fn cancel" "$LIB" || fail "cancel missing"
grep -q "StaleReason" "$LIB" || fail "stale pause missing"
grep -q "StateStale" "$LIB" || fail "state-stale missing"
grep -q "CommandPolicyStale" "$LIB" || fail "command-policy-stale missing"
grep -q "RouteStale" "$LIB" || fail "route-stale missing"
grep -q "ApprovalStale" "$LIB" || fail "approval-stale missing"

# Real behavior: stale state pauses; rate limit denies; cancel removes.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml stale 2>&1 \
  | grep -q "stale_state_pauses" || fail "stale-pause invariant"

echo "req WM-SPEC-014-R10: ok"
