#!/usr/bin/env sh
# WM-SPEC-016-R09: audio and visual packs carry license, provenance,
# hash, signature or user-local source, and permissions.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "pub struct AssetManifestEntry" "$LIB" || fail "manifest entry missing"
grep -q "pub license" "$LIB" || fail "license missing"
grep -q "pub provenance" "$LIB" || fail "provenance missing"
grep -q "pub sha256" "$LIB" || fail "hash missing"
grep -q "pub signature" "$LIB" || fail "signature missing"
grep -q "pub user_local" "$LIB" || fail "user-local source missing"
grep -q "pub permissions" "$LIB" || fail "permissions missing"
grep -q "pub fn validate" "$LIB" || fail "manifest validation missing"
echo "requirement WM-SPEC-016-R09 pack-provenance: ok"
