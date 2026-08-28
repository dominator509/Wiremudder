#!/usr/bin/env sh
# WM-SPEC-018-R05: Optional source checkout indexing is opt-in,
# local-first, idle-only, secret-aware, ignore-file-aware, resumable,
# and removable.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

grep -q "WM-SPEC-018-R05: Optional source checkout indexing is opt-in" \
  .agent/specs/SPEC-018-contextual-help-setup-coach-and-source-index.md \
  || fail "WM-SPEC-018-R05 missing from SPEC-018"

LIB=wirecore/crates/wire-help/src/lib.rs
grep -q "enable_source_index" "$LIB" || fail "opt-in missing"
grep -q "local_only" "$LIB" || fail "local-first missing"
grep -q "idle_only" "$LIB" || fail "idle-only missing"
grep -q "SecretDetected" "$LIB" || fail "secret-aware missing"
grep -q "ignore_patterns" "$LIB" || fail "ignore-file-aware missing"
grep -q "resume_from" "$LIB" || fail "resumable missing"
grep -q "remove_source_index" "$LIB" || fail "removable missing"
grep -q '"secret_entries_skipped"' schemas/wiremudder/help/source-index-state-v1.json \
  || fail "secret counter missing from schema"

echo "requirement WM-SPEC-018-R05 source-index: ok"
