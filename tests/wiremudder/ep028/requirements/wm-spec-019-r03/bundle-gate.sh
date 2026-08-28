#!/usr/bin/env sh
# WM-SPEC-019-R03: crash and diagnostic bundles are local, redacted,
# previewable, content-addressed, and never submitted without explicit
# user action or opt-in policy.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement wm-spec-019-r03: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-replay/src/lib.rs
[ -f "$LIB" ] || fail "wire-replay crate missing"
grep -q "approved_for_submission: false" "$LIB" || fail "not approved by default"
grep -q "fn approve" "$LIB" || fail "explicit approval path missing"
grep -q "content_sha256" "$LIB" || fail "content addressing missing"
grep -q "redact_text" "$LIB" || fail "redaction missing"
grep -q "preview" "$LIB" || fail "preview missing"
grep -q "approved_for_submission" schemas/wiremudder/telemetry/diagnostic-bundle.schema.json || fail "schema lacks approval gate"
echo "requirement wm-spec-019-r03 bundle-gate: ok"
