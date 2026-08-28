#!/usr/bin/env sh
# WM-FEAT-0059: optional wake phrase after opt-in.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0059: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct WakePhraseConfig" "$LIB" || fail "wake phrase config missing"
grep -q "pub fn set_wake_phrase" "$LIB" || fail "wake phrase setter missing"
grep -q "disabled by default" "$LIB" || fail "disabled-by-default missing"
grep -q "ConsentRequired" "$LIB" || fail "consent gate missing"
echo "feature WM-FEAT-0059 optional-wake-phrase: ok"
