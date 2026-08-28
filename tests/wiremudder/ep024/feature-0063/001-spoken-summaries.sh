#!/usr/bin/env sh
# WM-FEAT-0063: spoken room/map/quest/combat/setup summaries.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0063: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct SpokenSummary" "$LIB" || fail "spoken summary missing"
grep -q "pub fn summarize" "$LIB" || fail "summarize missing"
grep -q "pub source" "$LIB" || fail "source disclosure missing"
echo "feature WM-FEAT-0063 spoken-summaries: ok"
