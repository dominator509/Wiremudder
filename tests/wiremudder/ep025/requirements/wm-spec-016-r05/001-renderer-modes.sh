#!/usr/bin/env sh
# WM-SPEC-016-R05: renderer modes include disabled, static, low-power,
# no-animation, animated, and text-only fallback.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
for mode in Disabled Static LowPower NoAnimation Animated TextOnly; do
  grep -q "$mode" "$LIB" || fail "mode $mode missing"
done
grep -q "pub fn set_mode" "$LIB" || fail "mode setter missing"
echo "requirement WM-SPEC-016-R05 renderer-modes: ok"
