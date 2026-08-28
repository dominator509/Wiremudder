#!/usr/bin/env sh
# EP-030 M1 contract test: safe-import and session-defer semantics are
# anchored in accepted specifications so no later milestone can weaken them.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Importers are streaming and size-bounded and prevent traversal, entity
# expansion, decompression bombs, and executable surprise (WM-SPEC-021-R07).
grep -q "WM-SPEC-021-R07: Importers are streaming and size-bounded and prevent traversal, entity expansion, decompression bombs, and executable surprise" \
  .agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md \
  || fail "bounded-importer rule missing from SPEC-021"

# Unknown fields are preserved where safe or reported (WM-SPEC-021-R05).
grep -q "WM-SPEC-021-R05: Unknown fields are preserved where safe or reported; they are never silently discarded when loss would matter" \
  .agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md \
  || fail "unknown-field rule missing from SPEC-021"

# Updates and migrations defer during active sessions unless the user
# explicitly stops sessions and approves (WM-SPEC-020-R07).
grep -q "WM-SPEC-020-R07: Updates and migrations defer during active sessions unless the user explicitly stops sessions and approves" \
  .agent/specs/SPEC-020-updates-packages-supply-chain-and-release.md \
  || fail "session-defer rule missing from SPEC-020"

# Import runs in a constrained parser boundary and does not access secrets
# or the network (SPEC-021 security note).
grep -q "Import runs in a constrained parser boundary and does not access secrets or the network" \
  .agent/specs/SPEC-021-import-migration-and-ecosystem-compatibility.md \
  || fail "constrained-boundary rule missing from SPEC-021"

echo "contract EP-030 safe-import-and-defer: ok"
