#!/usr/bin/env sh
# WM-FEAT-0077: local/user-owned/signed/licensed assets.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0077: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
grep -q "pub struct AssetManifestEntry" "$LIB" || fail "asset manifest missing"
grep -q "pub license" "$LIB" || fail "license field missing"
grep -q "pub sha256" "$LIB" || fail "hash field missing"
grep -q "pub signature" "$LIB" || fail "signature field missing"
grep -q "pub user_local" "$LIB" || fail "user-local field missing"
grep -q "pub permissions" "$LIB" || fail "permissions field missing"
echo "feature WM-FEAT-0077 asset-provenance: ok"
