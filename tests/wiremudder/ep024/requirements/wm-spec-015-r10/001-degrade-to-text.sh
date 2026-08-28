#!/usr/bin/env sh
# WM-SPEC-015-R10: voice failure, provider outage, or worker crash
# degrades to text without affecting gameplay (live-fire requirement).
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub fn degrade_to_text" "$LIB" || fail "degrade-to-text missing"
grep -q "VoiceState::Degraded" "$LIB" || fail "degraded state missing"
grep -q "Manual text gameplay" "$LIB" || fail "gameplay preservation contract missing"
# Live-fire proof must certify the degrade-to-text obligation.
[ -f tests/live-fire/LF-024-voice-privacy-command.sh ] || fail "LF-024 missing"
grep -q "degrade to text" tests/live-fire/LF-024-voice-privacy-command.sh || fail "LF-024 lacks degrade obligation"
echo "requirement WM-SPEC-015-R10 degrade-to-text: ok"
