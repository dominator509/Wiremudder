#!/usr/bin/env sh
# WM-FEAT-0062: voice macros.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0062: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "pub struct VoiceMacro" "$LIB" || fail "voice macro missing"
grep -q "pub struct ActionProposal" "$LIB" || fail "action proposal missing"
grep -q "pub fn recognize" "$LIB" || fail "recognition missing"
grep -q "pub fn propose" "$LIB" || fail "proposal missing"
grep -q "WM-SPEC-009-R02" "$LIB" || fail "command-safety contract missing"
echo "feature WM-FEAT-0062 voice-macros: ok"
