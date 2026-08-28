#!/usr/bin/env sh
# WM-SPEC-026-R08: no hosted telemetry, crash reporting, or analytics
# endpoint is required for core operation.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement wm-spec-026-r08: FAIL - $1" >&2; exit 1; }
TEL=wirecore/crates/wire-telemetry/src/lib.rs
REP=wirecore/crates/wire-replay/src/lib.rs
[ -f "$TEL" ] || fail "wire-telemetry crate missing"
[ -f "$REP" ] || fail "wire-replay crate missing"
for lib in "$TEL" "$REP"; do
  if grep -qE "https?://[^ ]*(telemetry|crash|analytics|sentry)" "$lib"; then
    fail "hosted endpoint found in $lib"
  fi
done
grep -q "no remote egress" "$TEL" || fail "no-egress statement missing in telemetry"
grep -q "no remote egress" "$REP" || fail "no-egress statement missing in replay"
echo "requirement wm-spec-026-r08 no-hosted-telemetry: ok"
