#!/usr/bin/env sh
# WM-SPEC-019-R06: AI Debugger may analyze approved evidence and propose
# a hypothesis, reproduction, patch plan, tests, risk, and rollback but
# cannot self-certify success.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
grep -q "pub struct AiDiagnosis" "$LIB" || fail "AiDiagnosis missing"
grep -q "pub evidence" "$LIB" || fail "diagnosis lacks evidence"
grep -q "pub hypothesis" "$LIB" || fail "diagnosis lacks hypothesis"
grep -q "pub reproduction" "$LIB" || fail "diagnosis lacks reproduction"
grep -q "pub patch_plan" "$LIB" || fail "diagnosis lacks patch plan"
grep -q "pub tests" "$LIB" || fail "diagnosis lacks tests"
grep -q "pub risk" "$LIB" || fail "diagnosis lacks risk"
grep -q "pub rollback" "$LIB" || fail "diagnosis lacks rollback"
grep -q "self_certified: false" "$LIB" || fail "AI Debugger can self-certify success"
echo "requirement WM-SPEC-019-R06 ai-debugger-no-self-certify: ok"
