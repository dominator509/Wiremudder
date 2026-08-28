#!/usr/bin/env sh
# EP-021 requirement test: WM-SPEC-012-R01 World Brain models entities.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-012-r01: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-world-brain/src/lib.rs
grep -q "pub struct WorldBrain" "$LIB" || fail "WorldBrain missing"
grep -q "pub fn observe" "$LIB" || fail "observe missing"
grep -q "subject" "$LIB" || fail "subject missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "fact_records_provenance" || fail "provenance invariant"
echo "wm-spec-012-r01 World Brain entities: ok"
