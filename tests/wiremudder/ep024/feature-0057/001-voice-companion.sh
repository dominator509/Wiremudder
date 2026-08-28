#!/usr/bin/env sh
# WM-FEAT-0057: real-time conversational Voice Companion.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0057: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
[ -f "$LIB" ] || fail "wire-voice crate missing"
grep -q "pub struct VoiceCompanion" "$LIB" || fail "VoiceCompanion missing"
grep -q "pub fn snapshot" "$LIB" || fail "companion snapshot missing"
echo "feature WM-FEAT-0057 conversational-voice-companion: ok"
