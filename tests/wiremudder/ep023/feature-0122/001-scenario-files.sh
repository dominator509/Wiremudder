#!/usr/bin/env sh
# WM-FEAT-0122: scenario files.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0122: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "pub struct Scenario" "$LIB" || fail "Scenario missing"
grep -q "pub struct ScenarioStep" "$LIB" || fail "ScenarioStep missing"
grep -q "pub fn validate" "$LIB" || fail "scenario validation missing"
grep -q "MAX_SCENARIO_STEPS" "$LIB" || fail "scenario bound missing"
grep -q "scenario" schemas/wiremudder/headless/scenario-v1.json || fail "scenario schema missing"
echo "feature WM-FEAT-0122 scenario-files: ok"
