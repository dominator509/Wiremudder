#!/usr/bin/env sh
# WM-FEAT-0068: accessibility spoken mode.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0068: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub fn summarize" "$LIB" || fail "spoken summaries missing"
grep -q "pub fn set_combat_suppress" "$LIB" || fail "combat suppression missing"
grep -q "pub fn enqueue_speech" "$LIB" || fail "speech path missing"
grep -q "P3" "$LIB" || fail "P3 degradation contract missing"
echo "feature WM-FEAT-0068 accessibility-spoken-mode: ok"
