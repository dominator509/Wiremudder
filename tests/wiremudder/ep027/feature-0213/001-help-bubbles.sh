#!/usr/bin/env sh
# WM-FEAT-0213: circular help bubbles — bubbles beside fields with safe
# defaults, validation hints, privacy notes, and documentation links.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0213: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "FieldHelp" "$LIB" || fail "field help type missing"
grep -q "safe_default" "$LIB" || fail "safe default missing"
grep -q "validation_hint" "$LIB" || fail "validation hint missing"
grep -q "privacy_note" "$LIB" || fail "privacy note missing"
grep -q "doc_link" "$LIB" || fail "doc link missing"
grep -q "HelpBubbleQt" src/wiremudder/ui/help/help_boundary.h || fail "bubble surface missing from boundary"
echo "feature WM-FEAT-0213 help-bubbles: ok"
