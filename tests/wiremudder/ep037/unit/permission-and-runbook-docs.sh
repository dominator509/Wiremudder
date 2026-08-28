#!/usr/bin/env sh
# EP-037 M2 unit test: the package-author docs document every permission in
# the canonical schema enum and every update-policy kind, and the user docs
# match the real contract wording for runbooks and imports.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -f docs/wiremudder/package-author/README.md ] || fail "missing package-author guide"

# Every permission in the schema enum is documented.
perms=$(python3 -c "
import json
s=json.load(open('schemas/wiremudder/packages/manifest.schema.json'))
print(' '.join(s['properties']['requested_permissions']['items']['enum']))
")
for p in $perms; do
  grep -q "$p" docs/wiremudder/package-author/README.md \
    || fail "permission $p not documented"
done

# Update policy kinds are documented.
for k in never manual auto; do
  grep -q "\\b$k\\b" docs/wiremudder/package-author/README.md \
    || fail "update policy $k not documented"
done

# No silent permission expansion rule is documented.
grep -q "cannot silently expand permissions" docs/wiremudder/package-author/README.md \
  || fail "no-silent-expansion rule missing"

# WM-FEAT-0243 surface: operations docs mention backup, restore, rollback.
grep -qi "backup" docs/wiremudder/user/operations.md || fail "backup not documented"
grep -qi "restore" docs/wiremudder/user/operations.md || fail "restore not documented"
grep -qi "rollback" docs/wiremudder/user/operations.md || fail "rollback not documented"

echo "unit EP-037 permission-and-runbook-docs: ok"
