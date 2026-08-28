#!/usr/bin/env sh
# WM-FEAT-0216: local-only and remote-redacted help modes.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0216: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "HelpMode" "$LIB" || fail "help mode type missing"
grep -q "LocalOnly" "$LIB" || fail "local-only mode missing"
grep -q "RemoteRedacted" "$LIB" || fail "remote-redacted mode missing"
grep -q "pub fn set_mode" "$LIB" || fail "mode setter missing"
grep -q "HelpModeQt" src/wiremudder/ui/help/help_boundary.h || fail "mode surface missing from boundary"
echo "feature WM-FEAT-0216 help-modes: ok"
