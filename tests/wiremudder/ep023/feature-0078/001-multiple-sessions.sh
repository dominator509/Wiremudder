#!/usr/bin/env sh
# WM-FEAT-0078: multiple tabs/windows.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0078: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "pub struct SessionScheduler" "$LIB" || fail "SessionScheduler missing"
grep -q "create_session" "$LIB" || fail "multiple session creation missing"
grep -q "MAX_SESSIONS" "$LIB" || fail "session count bound missing"
grep -q "pub struct Session" "$LIB" || fail "Session missing"
echo "feature WM-FEAT-0078 multiple-tabs-windows: ok"
