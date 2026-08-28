#!/usr/bin/env sh
# WM-FEAT-0058: push-to-talk and hold-to-talk.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0058: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub enum ActivationMode" "$LIB" || fail "activation modes missing"
grep -q "PushToTalk" "$LIB" || fail "push-to-talk missing"
grep -q "HoldToTalk" "$LIB" || fail "hold-to-talk missing"
grep -q "pub fn begin_listen" "$LIB" || fail "listen missing"
echo "feature WM-FEAT-0058 push-to-talk-hold-to-talk: ok"
