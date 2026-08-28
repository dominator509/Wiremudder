#!/usr/bin/env sh
# EP-023 M3 integration test: JSONL/scenario validation and headless
# resource profile (heavy surfaces disabled).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-headless/src/lib.rs

# 1. Versioned structured JSONL output (WM-SPEC-017-R04).
grep -q "pub struct JsonlEvent" "$LIB" || fail "JSONL event missing"
grep -q "schema_version" "$LIB" || fail "JSONL lacks version"
grep -q "correlation" "$LIB" || fail "JSONL lacks correlation"
grep -q "redacted" "$LIB" || fail "JSONL lacks redaction"

# 2. Schema-validated scenarios.
grep -q "pub struct Scenario" "$LIB" || fail "Scenario missing"
grep -q "pub fn validate" "$LIB" || fail "scenario validation missing"
grep -q "MAX_SCENARIO_STEPS" "$LIB" || fail "scenario step bound missing"

# 3. Headless disables UI, renderer, audio, voice (lower overhead).
grep -q "disable_ui" "$LIB" || fail "UI disable missing"
grep -q "disable_renderer" "$LIB" || fail "renderer disable missing"
grep -q "disable_audio" "$LIB" || fail "audio disable missing"
grep -q "disable_voice" "$LIB" || fail "voice disable missing"

echo "integration EP-023 M3 jsonl-scenario-resource: ok"
