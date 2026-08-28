#!/usr/bin/env sh
# WM-FEAT-0132: local diagnostic bundles — local, redacted, previewable,
# content-addressed, never submitted without explicit user action
# (SPEC-019-R03).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0132: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-replay/src/lib.rs
[ -f "$LIB" ] || fail "wire-replay crate missing"
grep -q "DiagnosticBundle" "$LIB" || fail "diagnostic bundle missing"
grep -q "content_sha256" "$LIB" || fail "content addressing missing"
grep -q "approved_for_submission" "$LIB" || fail "approval gate missing"
grep -q "preview" "$LIB" || fail "preview missing"
grep -q "BundleBuilder" "$LIB" || fail "bundle builder missing"
grep -q "approved_for_submission" schemas/wiremudder/telemetry/diagnostic-bundle.schema.json || fail "schema lacks approval gate"
echo "feature WM-FEAT-0132 local-diagnostic-bundles: ok"
