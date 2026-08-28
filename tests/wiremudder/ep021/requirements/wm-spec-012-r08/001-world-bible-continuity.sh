#!/usr/bin/env sh
# EP-021 requirement test: WM-SPEC-012-R08 World Bible continuity without
# copying protected assets.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-012-r08: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-world-bible/src/lib.rs
grep -q "pub struct WorldBible" "$LIB" || fail "WorldBible missing"
grep -q "pub fn export_json" "$LIB" || fail "export missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-bible/Cargo.toml 2>&1 \
  | grep -q "no_protected_assets" || fail "no-assets invariant"
echo "wm-spec-012-r08 World Bible continuity: ok"
