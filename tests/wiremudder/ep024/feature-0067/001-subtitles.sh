#!/usr/bin/env sh
# WM-FEAT-0067: subtitles/transcript controls.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0067: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct SubtitleLine" "$LIB" || fail "subtitle missing"
grep -q "pub fn add_subtitle" "$LIB" || fail "subtitle add missing"
grep -q "pub fn set_transcript_retention" "$LIB" || fail "retention control missing"
grep -q "pub fn visible_subtitles" "$LIB" || fail "visible subtitles missing"
grep -q "private content suppressed by default" "$LIB" || fail "privacy suppression missing"
echo "feature WM-FEAT-0067 subtitles-transcript-controls: ok"
