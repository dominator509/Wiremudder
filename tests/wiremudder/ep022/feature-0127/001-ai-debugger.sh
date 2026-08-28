#!/usr/bin/env sh
# WM-FEAT-0127: AI Debugger.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0127: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
grep -q "pub struct AiDebugger" "$LIB" || fail "AiDebugger missing"
grep -q "approve_evidence" "$LIB" || fail "evidence approval missing"
grep -q "self_certified: false" "$LIB" || fail "AI Debugger can self-certify"
grep -q "DeniedPolicy" "$LIB" || fail "unapproved evidence not denied"
echo "feature WM-FEAT-0127 ai-debugger: ok"
