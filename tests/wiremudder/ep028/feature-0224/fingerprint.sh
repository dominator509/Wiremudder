#!/usr/bin/env sh
# WM-FEAT-0224: structured event fingerprints and correlation IDs —
# structural hashing, stable correlation, schema fields (SPEC-019-R02).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0224: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-telemetry/src/lib.rs
[ -f "$LIB" ] || fail "wire-telemetry crate missing"
grep -q "fingerprint_for" "$LIB" || fail "fingerprint generator missing"
grep -q "correlation_id" "$LIB" || fail "correlation id missing"
grep -q "Sha256" "$LIB" || fail "sha256 hashing missing"
grep -q '"fingerprint"' schemas/wiremudder/telemetry/event.schema.json || fail "schema lacks fingerprint"
grep -q '"correlation_id"' schemas/wiremudder/telemetry/event.schema.json || fail "schema lacks correlation id"
echo "feature WM-FEAT-0224 fingerprints-correlation: ok"
