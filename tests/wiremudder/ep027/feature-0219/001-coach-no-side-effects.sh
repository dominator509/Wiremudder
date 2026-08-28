#!/usr/bin/env sh
# WM-FEAT-0219: coach cannot directly change protected settings or
# send commands — apply is hard-denied; no command path on any surface.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0219: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "apply_step" "$LIB" || fail "apply denial missing"
grep -q "DeniedPolicy" "$LIB" || fail "policy denial missing"
grep -q "can_send_command" "$LIB" || fail "no-command check missing"
grep -q "side_effect_free" "$LIB" || fail "side-effect-free guarantee missing"
HDR=src/wiremudder/ui/help/help_boundary.h
grep -q "coachCanApply() const { return false; }" "$HDR" || fail "coach apply disabled on boundary"
grep -q "canChangeSettings() const { return false; }" "$HDR" || fail "settings mutation present on boundary"
grep -q "canSendCommand() const { return false; }" "$HDR" || fail "command path present on boundary"
echo "feature WM-FEAT-0219 coach-no-side-effects: ok"
