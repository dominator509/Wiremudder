#!/usr/bin/env sh
# WM-FEAT-0108: Trigger Test Lab.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0108: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
grep -q "pub struct TriggerLab" "$LIB" || fail "TriggerLab missing"
grep -q "pub fn replay" "$LIB" || fail "deterministic replay missing"
grep -q "pub struct ReplayFixture" "$LIB" || fail "ReplayFixture missing"
grep -q "pub fn validate" "$LIB" || fail "fixture validation missing"
echo "feature WM-FEAT-0108 trigger-test-lab: ok"
