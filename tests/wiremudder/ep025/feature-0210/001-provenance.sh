#!/usr/bin/env sh
# WM-FEAT-0210: renderer provenance tracking.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0210: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "pub fn track_provenance" "$LIB" || fail "provenance tracking missing"
grep -q "pub fn provenance" "$LIB" || fail "provenance view missing"
grep -q "MAX_PROVENANCE" "$LIB" || fail "provenance bound missing"
grep -q "pub provenance" "$LIB" || fail "emit provenance field missing"
echo "feature WM-FEAT-0210 renderer-provenance: ok"
