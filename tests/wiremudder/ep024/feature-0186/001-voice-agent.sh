#!/usr/bin/env sh
# WM-FEAT-0186: Voice Companion Agent with evidence, safety, rollback,
# and release-profile controls.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0186: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct VoiceCompanion" "$LIB" || fail "voice companion agent missing"
grep -q "pub fn emergency_stop" "$LIB" || fail "safety control missing"
grep -q "degrade_to_text" "$LIB" || fail "rollback/degrade missing"
grep -q "pub fn snapshot" "$LIB" || fail "observability snapshot missing"
echo "feature WM-FEAT-0186 voice-companion-agent: ok"
