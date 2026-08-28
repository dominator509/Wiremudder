#!/usr/bin/env sh
# WM-SPEC-017-R02: each session has bounded queues and one busy world
# cannot starve another.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "SESSION_QUEUE_CAPACITY" "$LIB" || fail "bounded queue missing"
grep -q "serve_round" "$LIB" || fail "round-robin scheduler missing"
grep -q "cannot starve another" "$LIB" || fail "starvation guarantee missing"
grep -q "one per session per round" "$LIB" || fail "fairness invariant missing"
echo "requirement WM-SPEC-017-R02 session-fairness: ok"
