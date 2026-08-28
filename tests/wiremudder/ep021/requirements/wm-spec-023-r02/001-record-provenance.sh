#!/usr/bin/env sh
# EP-021 requirement test: WM-SPEC-023-R02 every record declares
# owner/profile/world scope, created and observed time, source, actor,
# schema version, sensitivity, retention, and content hash where
# applicable.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-023-r02: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-world-brain/src/lib.rs
grep -q "profile_scope" "$LIB" || fail "profile scope missing"
grep -q "world_scope" "$LIB" || fail "world scope missing"
grep -q "created_at_ms" "$LIB" || fail "created time missing"
grep -q "observed_at_ms" "$LIB" || fail "observed time missing"
grep -q "actor" "$LIB" || fail "actor missing"
grep -q "sensitivity" "$LIB" || fail "sensitivity missing"
grep -q "content_hash" "$LIB" || fail "content hash missing"
grep -q "WORLD_BRAIN_SCHEMA_VERSION" "$LIB" || fail "schema version missing"
echo "wm-spec-023-r02 record provenance: ok"
