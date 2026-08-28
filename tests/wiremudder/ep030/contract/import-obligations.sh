#!/usr/bin/env sh
# EP-030 M1 contract test: the six acceptance obligations of the node
# contract are declared as binding requirements before product work:
# 1. Mudlet formats are discovered from source and corpus.
# 2. Every import is hashed and backed up.
# 3. Automation and permissions start disabled.
# 4. Conflicts and unsupported fields are reported.
# 5. Malformed and adversarial inputs fail safely.
# 6. Rollback leaves source and destination intact.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

for ob in "Mudlet formats are discovered from source and corpus" \
          "Every import is hashed and backed up" \
          "Automation and permissions start disabled" \
          "Conflicts and unsupported fields are reported" \
          "Malformed and adversarial inputs fail safely" \
          "Rollback leaves source and destination intact"; do
  grep -qF "$ob" .agent/node-contracts/EP-030.md || fail "obligation missing from EP-030 contract: $ob"
done

# Mudlet profile/package/map formats are discovered from the pinned source,
# not guessed (WM-SPEC-021-R01).
grep -q "WM-SPEC-021-R01: Mudlet profile, package, module, map, script, trigger, alias, timer, macro, layout, theme, and related formats are discovered from the pinned source and fixtures rather than guessed" \
  .agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md \
  || fail "format-discovery rule missing from SPEC-021"

# Every import creates a source hash, format version, provenance record,
# backup, normalized result, warning list, unsupported-item list, and
# rollback path (WM-SPEC-021-R03).
grep -q "WM-SPEC-021-R03: Every import creates a source hash, format version, provenance record, backup, normalized result, warning list, unsupported-item list, and rollback path" \
  .agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md \
  || fail "provenance rule missing from SPEC-021"

# Imported automation starts disabled or confirmation-gated with a
# migration report (WM-SPEC-008-R06).
grep -q "WM-SPEC-008-R06: Imported automation starts disabled or confirmation-gated and displays a migration report" \
  .agent/specs/SPEC-008-automation-scripting-plugins-packages-and-imports.md \
  || fail "disabled-automation rule missing from SPEC-008"

# A failed import leaves the original and destination unchanged except for
# a removable diagnostic report (WM-SPEC-021-R09).
grep -q "WM-SPEC-021-R09: A failed import leaves the original and destination unchanged except for a removable diagnostic report" \
  .agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md \
  || fail "rollback rule missing from SPEC-021"

echo "contract EP-030 import-obligations: ok"
