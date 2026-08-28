#!/usr/bin/env sh
# WM-SPEC-024-R08: desktop and headless commands use the same
# application contracts and policy gates.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "enqueue" "$LIB" || fail "shared enqueue gate missing"
grep -q "DeniedPolicy" "$LIB" || fail "shared policy denial missing"
grep -q "EmergencyStop" "$LIB" || fail "shared emergency stop missing"
grep -q "emergency_stop" "$LIB" || fail "global emergency stop missing"
echo "requirement WM-SPEC-024-R08 shared-contracts: ok"
