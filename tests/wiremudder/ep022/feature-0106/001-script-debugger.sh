#!/usr/bin/env sh
# WM-FEAT-0106: script editor/debugger/variable inspector.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0106: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
HDR=src/wiremudder/ui/power-tools/power_tools_boundary.h
grep -q "pub struct ScriptDebugger" "$LIB" || fail "ScriptDebugger missing"
grep -q "set_variable" "$LIB" || fail "variable inspection missing"
grep -q "pub fn timeline" "$LIB" || fail "event timeline missing"
grep -q "InspectedVariableQt" "$HDR" || fail "variable inspector pane surface missing"
grep -q "DebugEventQt" "$HDR" || fail "timeline pane surface missing"
echo "feature WM-FEAT-0106 script-editor-debugger-variable-inspector: ok"
