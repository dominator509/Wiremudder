#!/usr/bin/env sh
# WM-FEAT-0161: script debugger and variable inspector with evidence,
# safety, rollback, and release-profile controls.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0161: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
HDR=src/wiremudder/ui/power-tools/power_tools_boundary.h
grep -q "pub struct ScriptDebugger" "$LIB" || fail "ScriptDebugger missing"
grep -q "is_private" "$LIB" || fail "privacy scope missing"
grep -q '"<redacted>"' "$HDR" || fail "pane lacks redacted marker"
grep -q "canSendCommand() const { return false; }" "$HDR" || fail "pane has command path"
echo "feature WM-FEAT-0161 script-debugger-variable-inspector: ok"
