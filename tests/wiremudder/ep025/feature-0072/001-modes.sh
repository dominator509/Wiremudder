#!/usr/bin/env sh
# WM-FEAT-0072: static/low-power/no-animation modes.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0072: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "Static" "$LIB" || fail "static mode missing"
grep -q "LowPower" "$LIB" || fail "low-power mode missing"
grep -q "NoAnimation" "$LIB" || fail "no-animation mode missing"
grep -q "pub fn set_mode" "$LIB" || fail "mode setter missing"
grep -q "pub fn is_frozen" "$LIB" || fail "freeze state missing"
echo "feature WM-FEAT-0072 static-low-power-no-animation: ok"
