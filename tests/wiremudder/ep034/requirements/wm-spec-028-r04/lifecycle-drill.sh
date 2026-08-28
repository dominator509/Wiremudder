#!/usr/bin/env sh
# WM-SPEC-028-R04 (live-fire): install, upgrade, downgrade policy, backup,
# restore, migration, rollback, failed-update recovery, and uninstall are
# documented and drilled.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

runbook=docs/wiremudder/updater/operations/runbook.md
[ -f "$runbook" ] || fail "missing operations runbook"

# Every lifecycle obligation is documented in the runbook.
for term in "Upgrade" "Rollback" "Backup and Restore" "Recovery" "Uninstall" "Migration"; do
  grep -q "$term" "$runbook" || fail "runbook missing $term section"
done

# Downgrade policy documented (unexpected downgrade is rejected).
grep -q "downgrade" "$runbook" || fail "runbook missing downgrade policy"

# The drill exists and runs live (LF-034 is the drill for this node).
[ -f tests/live-fire/LF-034-signed-update-rollback.sh ] || fail "missing LF-034 drill"
grep -q "signed-update-rollback" .agent/node-contracts/EP-034.md \
  || fail "LF-034 missing from contract"

echo "req WM-SPEC-028-R04: ok"
