#!/usr/bin/env sh
# WM-SPEC-016-R01: original retro presentation; no protected third-party
# assets, sounds, trade dress, characters, or proprietary style sheets.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "no protected" "$LIB" || fail "protected-asset prohibition missing"
grep -q "ProtectedAsset" "$LIB" || fail "protected denial missing"
grep -q "UnlicensedAsset" "$LIB" || fail "unlicensed denial missing"
[ -d assets/wiremudder/renderer ] || fail "original assets missing"
grep -q "original:wiremudder:procedural" assets/wiremudder/renderer/manifest.json || fail "assets lack original provenance"
grep -q "CC0" assets/wiremudder/renderer/manifest.json || fail "assets lack license"
echo "requirement WM-SPEC-016-R01 original-rendering: ok"
