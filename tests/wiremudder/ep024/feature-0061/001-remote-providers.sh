#!/usr/bin/env sh
# WM-FEAT-0061: opt-in remote voice providers.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0061: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct RemoteSpeechPolicy" "$LIB" || fail "remote policy missing"
grep -q "pub fn allow_remote" "$LIB" || fail "remote gate missing"
grep -q "ConsentRequired" "$LIB" || fail "consent gate missing"
grep -q "LocalOnlyLockdown" "$LIB" || fail "local-only lockdown missing"
echo "feature WM-FEAT-0061 opt-in-remote-voice-providers: ok"
