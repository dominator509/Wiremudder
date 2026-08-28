#!/usr/bin/env sh
# WM-FEAT-0107: Macro Forge.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0107: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
grep -q "pub struct MacroForge" "$LIB" || fail "MacroForge missing"
grep -q "preview_only" "$LIB" || fail "drafts not previewable"
grep -q "pub fn approve" "$LIB" || fail "approval missing"
grep -q "pub fn is_runnable" "$LIB" || fail "runnable check missing"
echo "feature WM-FEAT-0107 macro-forge: ok"
