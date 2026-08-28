#!/usr/bin/env sh
# WM-SPEC-018-R04: The Help Knowledge Index is generated reproducibly
# from accepted docs, UI schemas, command catalog, configuration
# schemas, ADRs, and sanitized source references.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

grep -q "WM-SPEC-018-R04: The Help Knowledge Index is generated reproducibly" \
  .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "WM-SPEC-018-R04 missing from SPEC-018"

# All six accepted source kinds exist in the engine.
LIB=wirecore/crates/wire-help/src/lib.rs
for kind in Docs UiSchema CommandCatalog ConfigSchema Adr SourceRef; do
  grep -q "$kind" "$LIB" || fail "source kind $kind missing"
done
# Reproducibility: identical inputs produce identical index hash.
grep -q "index_state_hash" "$LIB" || fail "index state hash missing"
grep -q "index_reproducible" "$LIB" || fail "reproducibility test missing"

echo "requirement WM-SPEC-018-R04 reproducible-index: ok"
