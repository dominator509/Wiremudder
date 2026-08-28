#!/usr/bin/env sh
# WM-SPEC-028-R08: maintenance changes use the same Graphlock contracts,
# expected-file fences, tests, evidence, and rollback as initial development.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

# The node's own contracts and fences are in place (maintenance edits to
# this subsystem are gated the same way as initial development).
[ -f .agent/node-contracts/EP-034.md ] || fail "missing node contract"
[ -f .agent/expected-files/EP-034.txt ] || fail "missing static fence"
[ -f .agent/expected-files/EP-034.discovered.txt ] || fail "missing discovered amendment"
for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-034-$m.txt" ] || fail "missing milestone fence $m"
done

# The maintenance-change discipline is stated in the runbook and the
# Graphlock constitution.
grep -q "Maintenance Changes" docs/wiremudder/updater/operations/runbook.md \
  || fail "runbook missing maintenance-change discipline"
grep -q "WM-SPEC-028-R08" .agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md \
  || fail "SPEC-028 missing maintenance obligation"

# Rollback for inherited edits is a documented single command.
grep -q "git checkout -- src/CMakeLists.txt" .agent/expected-files/EP-034.discovered.txt \
  || fail "discovered amendment missing rollback command"

echo "req WM-SPEC-028-R08: ok"
