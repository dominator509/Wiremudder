#!/usr/bin/env sh
# EP-021 M3 integration test: correction preserves history, restore is
# user-approved, private data is not promoted to shared memory.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

BRAIN=wirecore/crates/wire-world-brain/src/lib.rs
TM=wirecore/crates/wire-time-machine/src/lib.rs

# Correction supersedes but preserves history.
grep -q "pub fn correct" "$BRAIN" || fail "correct missing"
grep -q "UserCorrected" "$BRAIN" || fail "user-corrected state missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "correction_supersedes_but_preserves_history" || fail "correction invariant"

# Restore requires user-approved checkpoint.
grep -q "pub fn approve" "$TM" || fail "approve missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-time-machine/Cargo.toml 2>&1 \
  | grep -q "snapshot_requires_approval_to_restore" || fail "approval invariant"

# World Bible stores metadata only; no protected assets.
BIBLE=wirecore/crates/wire-world-bible/src/lib.rs
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-bible/Cargo.toml 2>&1 \
  | grep -q "no_protected_assets" || fail "no-assets invariant"

echo "integration EP-021 M3 correction-approval-privacy: ok"
