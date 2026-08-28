#!/usr/bin/env sh
# EP-037 M5 feature test WM-FEAT-0243: backup, restore, rollback, and
# incident runbooks are documented with evidence, safety, rollback, and
# release-profile controls. The operations runbook must cover the full
# SPEC-026-R06 surface.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0243: FAIL - $1" >&2; exit 1; }

[ -f docs/wiremudder/operations/runbook.md ] || fail "missing operations runbook"

# SPEC-026-R06 surface: start, stop, health, recovery, backup, restore,
# upgrade, rollback, disable, diagnostics, incident triage.
for word in start stop health recovery backup restore upgrade rollback disable diagnostics incident; do
  grep -qi "$word" docs/wiremudder/operations/runbook.md \
    || fail "runbook missing $word"
done

# Health and readiness commands are concrete.
grep -q "node-verifiers/EP-037.sh verify" docs/wiremudder/operations/runbook.md \
  || fail "runbook missing health command"
grep -q "node-verify.sh EP-037" docs/wiremudder/operations/runbook.md \
  || fail "runbook missing readiness command"

# Backup is verified by hash.
grep -qi "verified by hash" docs/wiremudder/operations/runbook.md \
  || fail "backup hash verification not documented"

# Rollback preserves profile data.
grep -qi "preserves profile data" docs/wiremudder/operations/runbook.md \
  || fail "rollback data preservation not documented"

# The runbook is linked from user operations docs.
grep -q "operations/runbook.md" docs/wiremudder/user/operations.md \
  || fail "user ops doc missing runbook link"

echo "feature-0243 EP-037 backup-restore-rollback-runbooks: ok"
