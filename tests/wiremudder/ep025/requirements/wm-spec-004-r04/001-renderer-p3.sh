#!/usr/bin/env sh
# WM-SPEC-004-R04: P3 renderer/visual emits may drop, coalesce, freeze,
# cancel, or disable.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "P3" "$LIB" || fail "P3 contract missing"
grep -q "pub fn render_frame" "$LIB" || fail "frame budget missing"
grep -q "pub drops" "$LIB" || fail "drop counter missing"
grep -q "pub coalesces" "$LIB" || fail "coalesce counter missing"
grep -q "freeze" "$LIB" || fail "freeze behavior missing"
echo "requirement WM-SPEC-004-R04 renderer-p3-degradation: ok"
