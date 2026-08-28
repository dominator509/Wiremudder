#!/usr/bin/env sh
# WM-SPEC-008-R07: script editor, syntax checking, debug console,
# variable inspector, event replay, Macro Forge, and Trigger Test Lab are
# included in the graph.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-debugger/src/lib.rs
HDR=src/wiremudder/ui/power-tools/power_tools_boundary.h
# Macro Forge and Trigger Test Lab are explicit graph nodes.
grep -q "pub struct MacroForge" "$LIB" || fail "MacroForge missing from graph"
grep -q "pub struct TriggerLab" "$LIB" || fail "TriggerLab missing from graph"
# Variable inspector and event replay surfaces.
grep -q "pub struct ScriptDebugger" "$LIB" || fail "ScriptDebugger missing from graph"
grep -q "InspectedVariableQt" "$HDR" || fail "variable inspector missing from graph"
grep -q "DebugEventQt" "$HDR" || fail "event replay missing from graph"
echo "requirement WM-SPEC-008-R07 graph-inclusion: ok"
