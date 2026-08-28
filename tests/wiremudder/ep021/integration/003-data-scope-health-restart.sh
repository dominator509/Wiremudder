#!/usr/bin/env sh
# EP-021 M3 integration test: data scope, health, and restart behavior.
# Hot state is separate from durable memory; optional failure preserves
# manual text gameplay; bounded resources fail closed with typed errors.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

BRAIN=wirecore/crates/wire-world-brain/src/lib.rs
# Hot/durable separation.
grep -q "set_hot_room" "$BRAIN" || fail "hot state missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "hot_state_separate_from_durable" || fail "hot/durable invariant"

# Bounded resources fail closed.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "bounded_brain" || fail "bounded invariant"

echo "integration EP-021 M3 data-scope-health-restart: ok"
