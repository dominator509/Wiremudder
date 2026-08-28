#!/usr/bin/env sh
# WM-FEAT-0111: world onboarding wizard — coach steps guide setup and
# capability confirmation gates onboarding.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0111: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "add_coach_step" "$LIB" || fail "coach steps missing"
grep -q "pub fn propose" "$LIB" || fail "coach propose missing"
grep -q "confirm_capability" "$LIB" || fail "capability confirmation missing"
grep -q "confirmed_capabilities" "$LIB" || fail "confirmed capabilities missing"
echo "feature WM-FEAT-0111 world-onboarding-wizard: ok"
