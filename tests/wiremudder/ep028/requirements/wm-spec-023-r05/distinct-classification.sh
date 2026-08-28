#!/usr/bin/env sh
# WM-SPEC-023-R05: private, secret, diagnostic, voice, transcript, and
# public content use distinct data classifications and default retention.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement wm-spec-023-r05: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-telemetry/src/lib.rs
[ -f "$LIB" ] || fail "wire-telemetry crate missing"
for cls in Public Private Secret Diagnostic Voice Transcript; do
  grep -q "$cls" "$LIB" || fail "classification $cls missing"
done
grep -q "default_retention_days" "$LIB" || fail "distinct retention missing"
grep -q "classification" "$LIB" || fail "classification field missing"
echo "requirement wm-spec-023-r05 distinct-classification: ok"
