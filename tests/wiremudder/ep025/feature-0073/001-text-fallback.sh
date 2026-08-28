#!/usr/bin/env sh
# WM-FEAT-0073: text-only fallback.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0073: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "TextOnly" "$LIB" || fail "text-only mode missing"
grep -q "pub fn degrade_to_text" "$LIB" || fail "degrade-to-text missing"
grep -q "text gameplay" "$LIB" || fail "gameplay preservation missing"
echo "feature WM-FEAT-0073 text-only-fallback: ok"
