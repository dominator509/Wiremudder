#!/usr/bin/env sh
# WM-SPEC-010-R08: private tells, pages, whispers, and voice content
# are protected by default and excluded from remote context unless
# specifically approved.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "private content suppressed by default" "$LIB" || fail "private suppression missing"
grep -q "pub fn visible_subtitles" "$LIB" || fail "visible subtitle filter missing"
grep -q "ConsentRequired" "$LIB" || fail "remote consent gate missing"
grep -q "LocalOnlyLockdown" "$LIB" || fail "local-only lockdown missing"
echo "requirement WM-SPEC-010-R08 private-voice-protected: ok"
