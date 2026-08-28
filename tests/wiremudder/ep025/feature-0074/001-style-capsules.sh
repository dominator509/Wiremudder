#!/usr/bin/env sh
# WM-FEAT-0074: style capsules from World Bible.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0074: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "pub struct StyleCapsule" "$LIB" || fail "style capsule missing"
grep -q "world-bible" "$LIB" || fail "world bible provenance missing"
grep -q "pub fn add_style_capsule" "$LIB" || fail "capsule registry missing"
grep -q "palette" "$LIB" || fail "palette missing"
echo "feature WM-FEAT-0074 style-capsules-from-world-bible: ok"
