#!/usr/bin/env sh
# WM-FEAT-0215: Ask WireMudder AI handoff — scoped sanitized context
# with only approved references; secrets redacted.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0215: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "AskContext" "$LIB" || fail "ask context type missing"
grep -q "build_ask_context" "$LIB" || fail "ask context builder missing"
grep -q "sanitized_ui_state" "$LIB" || fail "sanitized state missing"
grep -q "redact_secrets" "$LIB" || fail "secret redaction missing"
grep -q '"sanitized_ui_state"' schemas/wiremudder/help/ask-context-v1.json || fail "schema lacks sanitized state"
echo "feature WM-FEAT-0215 ask-wiremudder-ai: ok"
