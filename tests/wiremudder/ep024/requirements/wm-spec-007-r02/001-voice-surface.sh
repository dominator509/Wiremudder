#!/usr/bin/env sh
# WM-SPEC-007-R02: WireMudder surfaces include the voice view where
# owning nodes are enabled.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct VoiceCompanion" "$LIB" || fail "voice surface missing"
[ -f src/wiremudder/ui/voice/voice_boundary.h ] || fail "voice UI boundary missing"
grep -q "wiremudder/ui/voice/voice_boundary.cpp" src/CMakeLists.txt || fail "voice surface not wired into client"
echo "requirement WM-SPEC-007-R02 voice-surface: ok"
