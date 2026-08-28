#!/usr/bin/env sh
# WM-FEAT-0212: different voice styles for copilot, mapper, quest,
# safety, narrator, renderer, and help agents.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0212: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "per-agent voice styles" "$LIB" || fail "per-agent styles contract missing"
grep -q "pub fn add_style" "$LIB" || fail "style registry missing"
grep -q '"agent"' schemas/wiremudder/voice/style-v1.json || fail "agent kind missing from schema"
grep -q "ProtectedVoice" "$LIB" || fail "protected voice denial missing"
echo "feature WM-FEAT-0212 different-agent-voice-styles: ok"
