#!/usr/bin/env sh
# WM-SPEC-026-R01: structured logs use time, severity, subsystem,
# priority, app version, platform, session/profile hashes, correlation,
# event, error, latency, queue, drop/coalesce, feature, privacy, and
# redaction fields.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-headless/src/lib.rs
grep -q "pub struct JsonlEvent" "$LIB" || fail "JsonlEvent missing"
grep -q "pub time_ms" "$LIB" || fail "time missing"
grep -q "pub severity" "$LIB" || fail "severity missing"
grep -q "pub subsystem" "$LIB" || fail "subsystem missing"
grep -q "pub priority" "$LIB" || fail "priority missing"
grep -q "pub app_version" "$LIB" || fail "app version missing"
grep -q "pub platform" "$LIB" || fail "platform missing"
grep -q "pub correlation" "$LIB" || fail "correlation missing"
grep -q "pub error" "$LIB" || fail "error missing"
grep -q "pub latency_ms" "$LIB" || fail "latency missing"
grep -q "pub queue" "$LIB" || fail "queue missing"
grep -q "pub drop" "$LIB" || fail "drop missing"
grep -q "pub coalesce" "$LIB" || fail "coalesce missing"
grep -q "pub feature" "$LIB" || fail "feature missing"
grep -q "pub privacy" "$LIB" || fail "privacy missing"
grep -q "pub redacted" "$LIB" || fail "redaction missing"
echo "requirement WM-SPEC-026-R01 structured-log-fields: ok"
