#!/usr/bin/env sh
# WM-FEAT-0123: JSONL event output.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0123: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "pub struct JsonlEvent" "$LIB" || fail "JsonlEvent missing"
grep -q "schema_version" "$LIB" || fail "JSONL not versioned"
grep -q "correlation" "$LIB" || fail "JSONL lacks correlation"
grep -q "redacted" "$LIB" || fail "JSONL lacks redaction"
grep -q "jsonl" schemas/wiremudder/headless/jsonl-event-v1.json || fail "JSONL schema missing"
echo "feature WM-FEAT-0123 jsonl-event-output: ok"
