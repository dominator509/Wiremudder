#!/usr/bin/env sh
# WM-FEAT-0060: local-first STT/TTS.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0060: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub fn enqueue_speech" "$LIB" || fail "speech enqueue missing"
grep -q '"local"' "$LIB" || fail "local provider path missing"
grep -q "local_only: true" "$LIB" || fail "local-only default missing"
grep -q "MAX_SPEECH_QUEUE" "$LIB" || fail "bounded speech queue missing"
echo "feature WM-FEAT-0060 local-first-stt-tts: ok"
