#!/usr/bin/env sh
# WM-FEAT-0070: persistent room backdrops.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0070: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "pub struct StyleCapsule" "$LIB" || fail "style capsule missing"
grep -q "room_ids" "$LIB" || fail "room backdrop mapping missing"
grep -q "pub fn add_style_capsule" "$LIB" || fail "capsule registry missing"
echo "feature WM-FEAT-0070 persistent-room-backdrops: ok"
