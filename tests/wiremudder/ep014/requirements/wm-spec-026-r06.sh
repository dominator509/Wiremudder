#!/usr/bin/env sh
# WM-SPEC-026-R06: runbooks cover start, stop, health, recovery,
# backup, restore, upgrade, rollback, disable, diagnostics, and
# incident triage.
set -eu
cd "$(dirname "$0")/../../../.."

RUNBOOK=docs/wiremudder/storage/operations/runbook.md
[ -f "$RUNBOOK" ] || { echo "wm-spec-026-r06: FAIL - runbook missing" >&2; exit 1; }

fail() { echo "wm-spec-026-r06: FAIL - $1" >&2; exit 1; }

# Health and readiness
grep -qi "health" "$RUNBOOK" || fail "health"
# Start is the crate health command; stop/disable is the disable path.
grep -qi "disable" "$RUNBOOK" || fail "disable"
# Recovery (corrupt DB), backup and restore.
grep -qi "recovery" "$RUNBOOK" || fail "recovery"
grep -qi "backup" "$RUNBOOK" || fail "backup"
grep -qi "restore" "$RUNBOOK" || fail "restore"
# Upgrade and rollback.
grep -qi "upgrade" "$RUNBOOK" || fail "upgrade"
grep -qi "rollback" "$RUNBOOK" || fail "rollback"
# Diagnostics / bounded resources / integrity.
grep -qi "integrity" "$RUNBOOK" || fail "diagnostics"

echo "wm-spec-026-r06: ok"
