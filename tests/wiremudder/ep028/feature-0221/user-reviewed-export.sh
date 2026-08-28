#!/usr/bin/env sh
# WM-FEAT-0221: user-reviewed diagnostic export — export is a
# user-visible effect with scope and content review (SPEC-019 Security
# and Privacy; SPEC-010 privacy firewall).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0221: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-replay/src/lib.rs
[ -f "$LIB" ] || fail "wire-replay crate missing"
grep -q "export_bytes" "$LIB" || fail "export surface missing"
grep -q "approve" "$LIB" || fail "user approval path missing"
grep -q "preview()" "$LIB" || fail "content review surface missing"
grep -q "is_approved" "$LIB" || fail "approval state missing"
grep -q "Diagnostic export is a user-visible effect" .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md || fail "spec lacks user-visible effect rule"
echo "feature WM-FEAT-0221 user-reviewed-diagnostic-export: ok"
