#!/usr/bin/env sh
# WM-FEAT-0225: severity classification — critical/error/warn/info/debug
# with schema enum (SPEC-019-R02).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0225: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-telemetry/src/lib.rs
[ -f "$LIB" ] || fail "wire-telemetry crate missing"
grep -q "enum Severity" "$LIB" || fail "severity enum missing"
grep -q "Critical" "$LIB" || fail "critical severity missing"
grep -q '"severity"' schemas/wiremudder/telemetry/event.schema.json || fail "schema lacks severity"
grep -q '"debug", "info", "warn", "error", "critical"' schemas/wiremudder/telemetry/event.schema.json || fail "schema severity enum incomplete"
grep -q "Severity" src/wiremudder/ui/diagnostics/diagnostics_boundary.h || fail "pane lacks severity surface"
echo "feature WM-FEAT-0225 severity-classification: ok"
