#!/usr/bin/env sh
# WM-FEAT-0209: renderer confidence display.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0209: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "pub confidence: u8" "$LIB" || fail "confidence field missing"
grep -q "pub inferred" "$LIB" || fail "inferred flag missing"
grep -q "visible confidence" "$LIB" || fail "visible-confidence contract missing"
echo "feature WM-FEAT-0209 renderer-confidence: ok"
