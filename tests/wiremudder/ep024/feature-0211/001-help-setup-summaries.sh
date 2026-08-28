#!/usr/bin/env sh
# WM-FEAT-0211: spoken help and setup summaries.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0211: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct SpokenSummary" "$LIB" || fail "spoken summary missing"
grep -q "help" "$LIB" || fail "help summary missing"
grep -q "setup" "$LIB" || fail "setup summary missing"
grep -q "pub source" "$LIB" || fail "source disclosure missing"
echo "feature WM-FEAT-0211 spoken-help-setup-summaries: ok"
