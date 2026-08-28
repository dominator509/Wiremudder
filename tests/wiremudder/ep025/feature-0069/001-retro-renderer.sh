#!/usr/bin/env sh
# WM-FEAT-0069: original retro tile/sprite/diorama renderer.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0069: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
[ -f "$LIB" ] || fail "wire-renderer crate missing"
grep -q "pub struct RetroRenderer" "$LIB" || fail "RetroRenderer missing"
grep -q "no protected" "$LIB" || fail "original-asset guarantee missing"
[ -d assets/wiremudder/renderer ] || fail "original assets missing"
grep -q "original:wiremudder:procedural" assets/wiremudder/renderer/manifest.json || fail "assets lack provenance"
echo "feature WM-FEAT-0069 original-retro-renderer: ok"
