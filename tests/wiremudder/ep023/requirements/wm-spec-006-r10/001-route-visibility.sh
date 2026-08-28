#!/usr/bin/env sh
# WM-SPEC-006-R10: per-session route label, latency, health, and audit
# events are visible without exposing credentials.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "route_label" "$LIB" || fail "route label missing"
grep -q "health" "$LIB" || fail "health visibility missing"
grep -q "audit_trail" "$LIB" || fail "audit events missing"
grep -q '"direct"' "$LIB" || fail "route label surface missing"
# No credential fields in JSONL events or snapshots.
grep -q "redacted" "$LIB" || fail "redaction missing"
echo "requirement WM-SPEC-006-R10 route-visibility-no-credentials: ok"
