#!/usr/bin/env sh
# WM-FEAT-0208: clickable and visible exits when available.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0208: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "pub struct ClickableExit" "$LIB" || fail "clickable exit missing"
grep -q "pub visible" "$LIB" || fail "visibility field missing"
grep -q "pub fn propose" "$LIB" || fail "proposal path missing"
grep -q "pub struct ExitProposal" "$LIB" || fail "exit proposal missing"
grep -q "cannot spoof" "$LIB" || fail "anti-spoof guarantee missing"
echo "feature WM-FEAT-0208 clickable-exits: ok"
