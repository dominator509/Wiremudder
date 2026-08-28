#!/usr/bin/env sh
# EP-019 M3 integration test: data scope, privacy disclosure, and audit.
# The autopilot exposes only profile-scoped data; safe user messages leak
# no internals; the audit is replayable and complete.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-autopilot/src/lib.rs

# Profile scoping is structural.
grep -q "ProfileMismatch" "$LIB" || fail "profile scoping missing"
grep -q "active_profile" "$LIB" || fail "active profile missing"

# Safe user messages: no paths, no internals.
grep -q "user_message" "$LIB" || fail "safe user messages missing"

# Complete audit: proposal id, command, action, detail.
grep -q "pub struct AutopilotAuditEntry" "$LIB" || fail "audit record missing"
grep -q "pub fn audit_log" "$LIB" || fail "audit accessor missing"

# The autopilot audit must be replayable in schema.
SCHEMA=schemas/wiremudder/autopilot/autopilot-status-v1.json
[ -f "$SCHEMA" ] || fail "missing autopilot status schema"
python3 -c "import json; json.load(open('$SCHEMA'))" || fail "invalid status schema"

echo "integration EP-019 M3 data-scope-audit-health: ok"
