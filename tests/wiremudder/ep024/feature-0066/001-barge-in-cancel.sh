#!/usr/bin/env sh
# WM-FEAT-0066: barge-in/cancel.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0066: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub fn barge_in" "$LIB" || fail "barge-in missing"
grep -q "pub fn cancel_job" "$LIB" || fail "cancel missing"
grep -q "BargeIn" "$LIB" || fail "barge-in mic state missing"
echo "feature WM-FEAT-0066 barge-in-cancel: ok"
