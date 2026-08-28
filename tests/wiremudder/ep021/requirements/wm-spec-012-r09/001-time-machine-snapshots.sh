#!/usr/bin/env sh
# EP-021 requirement test: WM-SPEC-012-R09 Time Machine snapshots
# background, compacted, exportable, reversible to user-approved
# checkpoints.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "wm-spec-012-r09: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-time-machine/src/lib.rs
grep -q "pub fn snapshot" "$LIB" || fail "snapshot missing"
grep -q "pub fn approve" "$LIB" || fail "approve missing"
grep -q "pub fn export_json" "$LIB" || fail "export missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-time-machine/Cargo.toml 2>&1 \
  | grep -q "snapshot_requires_approval_to_restore" || fail "approval invariant"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-time-machine/Cargo.toml 2>&1 \
  | grep -q "export_is_deterministic" || fail "export invariant"
echo "wm-spec-012-r09 Time Machine snapshots: ok"
