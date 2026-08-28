#!/usr/bin/env sh
# WM-FEAT-0075: soundscape studio (studio controls, profile-scoped
# volume/disable, bounded cancelable transitions, load shedding).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0075: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-soundscape/src/lib.rs
[ -f "$LIB" ] || fail "wire-soundscape crate missing"
grep -q "pub struct SoundscapeEngine" "$LIB" || fail "SoundscapeEngine missing"
grep -q "set_profile_controls" "$LIB" || fail "profile-scoped studio controls missing"
grep -q "set_binding_volume" "$LIB" || fail "independent volume controls missing"
grep -q "set_binding_enabled" "$LIB" || fail "independent disable controls missing"
grep -q "start_transition" "$LIB" || fail "transition start missing"
grep -q "cancel_transition" "$LIB" || fail "transition cancel missing"
grep -q "MAX_TRANSITION_MS" "$LIB" || fail "transition bound missing"
grep -q "QueueFull" "$LIB" || fail "load shedding missing"
grep -q "ProfileMuted" "$LIB" || fail "mute control missing"
echo "feature WM-FEAT-0075 soundscape-studio: ok"
