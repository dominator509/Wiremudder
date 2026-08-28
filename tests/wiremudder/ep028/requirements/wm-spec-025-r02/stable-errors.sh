#!/usr/bin/env sh
# WM-SPEC-025-R02: every public error has a stable code, safe message,
# correlation ID, retry class, user action, diagnostic reference, and
# redacted internal cause.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement wm-spec-025-r02: FAIL - $1" >&2; exit 1; }
TEL=wirecore/crates/wire-telemetry/src/lib.rs
REP=wirecore/crates/wire-replay/src/lib.rs
[ -f "$TEL" ] || fail "wire-telemetry crate missing"
[ -f "$REP" ] || fail "wire-replay crate missing"
for lib in "$TEL" "$REP"; do
  grep -q "pub code" "$lib" || fail "stable code missing in $lib"
  grep -q "pub message" "$lib" || fail "safe message missing in $lib"
  grep -q "correlation_id" "$lib" || fail "correlation id missing in $lib"
  grep -q "retry_class" "$lib" || fail "retry class missing in $lib"
  grep -q "user_action" "$lib" || fail "user action missing in $lib"
  grep -q "diagnostic_ref" "$lib" || fail "diagnostic ref missing in $lib"
  grep -q "internal_cause" "$lib" || fail "redacted cause missing in $lib"
done
echo "requirement wm-spec-025-r02 stable-errors: ok"
