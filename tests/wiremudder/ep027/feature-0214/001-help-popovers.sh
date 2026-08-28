#!/usr/bin/env sh
# WM-FEAT-0214: help popovers with safe defaults, validation hints,
# privacy notes, and documentation links.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0214: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "add_field_help" "$LIB" || fail "field help registration missing"
grep -q "pub fn field_help" "$LIB" || fail "field help lookup missing"
grep -q '"safe_default"' schemas/wiremudder/help/field-help-v1.json || fail "schema lacks safe default"
grep -q '"privacy_note"' schemas/wiremudder/help/field-help-v1.json || fail "schema lacks privacy note"
grep -q "HelpBubbleQt" src/wiremudder/ui/help/help_boundary.h || fail "popover surface missing from boundary"
echo "feature WM-FEAT-0214 help-popovers: ok"
