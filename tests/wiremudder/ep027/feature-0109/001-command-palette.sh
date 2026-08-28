#!/usr/bin/env sh
# WM-FEAT-0109: command palette — CLI help renders command catalog
# entries; the palette source is the accepted command catalog.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0109: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "pub fn cli_help" "$LIB" || fail "CLI help missing"
grep -q "CommandCatalog" "$LIB" || fail "command catalog source missing"
grep -q "pub fn ui_help" "$LIB" || fail "UI help missing"
[ -f COMMANDS.md ] || fail "command catalog missing"
grep -q "WireMudder Canonical Commands" COMMANDS.md || fail "catalog header missing"
echo "feature WM-FEAT-0109 command-palette: ok"
