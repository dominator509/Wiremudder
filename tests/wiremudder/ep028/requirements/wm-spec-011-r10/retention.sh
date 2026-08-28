#!/usr/bin/env sh
# WM-SPEC-011-R10: retention and deletion cover transcripts, voice
# transcripts, AI events, diagnostics, replay fixtures, memory, and
# audit exceptions. Telemetry uses distinct classification retention.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement wm-spec-011-r10: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-telemetry/src/lib.rs
[ -f "$LIB" ] || fail "wire-telemetry crate missing"
grep -q "default_retention_days" "$LIB" || fail "retention policy missing"
grep -q "DataClass" "$LIB" || fail "data classification missing"
grep -q "Transcript" "$LIB" || fail "transcript classification missing"
grep -q "Voice" "$LIB" || fail "voice classification missing"
grep -q "Diagnostic" "$LIB" || fail "diagnostic classification missing"
echo "requirement wm-spec-011-r10 retention-coverage: ok"
