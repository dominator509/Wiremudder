#!/usr/bin/env sh
# WM-FEAT-0064: per-character voice profiles.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0064: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct VoiceStyle" "$LIB" || fail "voice style missing"
grep -q '"character"' "$LIB" || fail "character style kind missing"
grep -q "pub fn add_style" "$LIB" || fail "style registry missing"
echo "feature WM-FEAT-0064 per-character-voice-profiles: ok"
