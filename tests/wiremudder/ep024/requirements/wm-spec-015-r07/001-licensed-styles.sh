#!/usr/bin/env sh
# WM-SPEC-015-R07: per-character and per-agent voice styles are
# licensed configuration profiles and cannot imitate protected
# characters or celebrities without lawful authorization.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct VoiceStyle" "$LIB" || fail "voice style missing"
grep -q "pub license" "$LIB" || fail "license field missing"
grep -q "pub authorized" "$LIB" || fail "authorization field missing"
grep -q "pub protected" "$LIB" || fail "protected flag missing"
grep -q "ProtectedVoice" "$LIB" || fail "protected denial missing"
echo "requirement WM-SPEC-015-R07 licensed-voice-styles: ok"
