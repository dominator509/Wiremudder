#!/usr/bin/env sh
# WM-SPEC-017-R04: headless mode emits versioned structured JSONL and
# can disable UI, renderer, audio, and voice for lower overhead.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "pub struct JsonlEvent" "$LIB" || fail "JSONL event missing"
grep -q "schema_version" "$LIB" || fail "JSONL not versioned"
grep -q "disable_ui" "$LIB" || fail "UI disable missing"
grep -q "disable_renderer" "$LIB" || fail "renderer disable missing"
grep -q "disable_audio" "$LIB" || fail "audio disable missing"
grep -q "disable_voice" "$LIB" || fail "voice disable missing"
echo "requirement WM-SPEC-017-R04 headless-jsonl-disable: ok"
