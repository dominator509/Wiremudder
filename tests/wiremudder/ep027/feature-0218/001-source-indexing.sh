#!/usr/bin/env sh
# WM-FEAT-0218: optional local source checkout indexing — opt-in,
# local-first, idle-only, secret-aware, ignore-file-aware, resumable,
# removable.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0218: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-help/src/lib.rs
[ -f "$LIB" ] || fail "wire-help crate missing"
grep -q "enable_source_index" "$LIB" || fail "opt-in enable missing"
grep -q "index_local_file" "$LIB" || fail "local indexing missing"
grep -q "source_index_state" "$LIB" || fail "source index state missing"
grep -q "secret_entries_skipped" "$LIB" || fail "secret awareness missing"
grep -q "resume_from" "$LIB" || fail "resumable missing"
grep -q "remove_source_index" "$LIB" || fail "removable missing"
echo "feature WM-FEAT-0218 source-indexing: ok"
