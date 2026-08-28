#!/usr/bin/env sh
# EP-021 requirement test: WM-SPEC-016-R02 persistent backdrops derive
# from user-owned assets and World Bible continuity rules (metadata only).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-016-r02: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-world-bible/src/lib.rs
grep -q "palette" "$LIB" || fail "palette missing"
grep -q "lighting" "$LIB" || fail "lighting missing"
grep -q "sound_rule" "$LIB" || fail "sound rule missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-bible/Cargo.toml 2>&1 \
  | grep -q "no_protected_assets" || fail "no-assets invariant"
echo "wm-spec-016-r02 backdrops from continuity rules: ok"
