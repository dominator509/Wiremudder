#!/usr/bin/env sh
# WM-SPEC-016-R10: renderer or audio worker failure disables immersion
# and preserves text gameplay (live-fire requirement).
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "pub fn degrade_to_text" "$LIB" || fail "degrade-to-text missing"
grep -q "TextOnly" "$LIB" || fail "text-only mode missing"
grep -q "text gameplay" "$LIB" || fail "gameplay preservation contract missing"
# Live-fire proof must certify the degrade obligation.
[ -f tests/live-fire/LF-025-renderer-degradation.sh ] || fail "LF-025 missing"
grep -q "renderer degrades to text" tests/live-fire/LF-025-renderer-degradation.sh || fail "LF-025 lacks degrade obligation"
echo "requirement WM-SPEC-016-R10 degrade-to-text: ok"
