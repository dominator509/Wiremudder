#!/usr/bin/env sh
# WM-FEAT-0125: multi-session orchestration rules.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0125: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "pub struct CrossSessionRule" "$LIB" || fail "CrossSessionRule missing"
grep -q "audit_trail" "$LIB" || fail "explicit audited rules missing"
grep -q "session-enqueue" "$LIB" || fail "enqueue not audited"
grep -q "emergency-stop global" "$LIB" || fail "emergency stop not audited"
echo "feature WM-FEAT-0125 multi-session-orchestration-rules: ok"
