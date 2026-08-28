#!/usr/bin/env sh
# EP-037 M1 contract test: the documentation surfaces this node must cover
# exist and carry the exact anchors the node contract requires — the package
# manifest schema, the permission and update rules, the runbook requirements,
# and the release documentation requirements.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Package-author surface: the real package manifest schema exists.
[ -f schemas/wiremudder/packages/manifest.schema.json ] \
  || fail "missing package manifest schema"
grep -q "permissions" schemas/wiremudder/packages/manifest.schema.json \
  || fail "manifest schema missing permissions"

# Permission and update rules (SPEC-008).
for r in WM-SPEC-008-R03 WM-SPEC-008-R04 WM-SPEC-008-R05; do
  grep -q "$r" .agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md \
    || fail "missing $r in SPEC-008"
done

# Runbook surface (SPEC-026-R06) for WM-FEAT-0243.
grep -q "WM-SPEC-026-R06" .agent/specs/SPEC-026-observability-operations-and-diagnostics.md \
  || fail "missing WM-SPEC-026-R06 in SPEC-026"

# Release/install/rollback documentation surface (SPEC-028-R04/R05).
for r in WM-SPEC-028-R04 WM-SPEC-028-R05; do
  grep -q "$r" .agent/specs/SPEC-028-production-readiness-ship-and-maintenance.md \
    || fail "missing $r in SPEC-028"
done

# Owning specs all exist.
for s in SPEC-000-product-scope-and-release-profiles \
         SPEC-018-contextual-help-setup-coach-and-source-index \
         SPEC-021-import-migration-and-ecosystem-compatibility; do
  [ -f ".agent/specs/$s.md" ] || fail "missing spec $s"
done

echo "contract EP-037 documentation-surfaces: ok"
