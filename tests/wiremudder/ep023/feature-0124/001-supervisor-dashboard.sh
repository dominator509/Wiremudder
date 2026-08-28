#!/usr/bin/env sh
# WM-FEAT-0124: Headless Supervisor Dashboard.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0124: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "pub struct Supervisor" "$LIB" || fail "Supervisor missing"
grep -q "pub struct SupervisorSnapshot" "$LIB" || fail "SupervisorSnapshot missing"
grep -q "risk_queue_len" "$LIB" || fail "risk queue reporting missing"
grep -q "token_spend" "$LIB" || fail "token spend reporting missing"
grep -q "health" "$LIB" || fail "health reporting missing"
grep -q "is_passive" "$LIB" || fail "supervisor not passive"
echo "feature WM-FEAT-0124 supervisor-dashboard: ok"
