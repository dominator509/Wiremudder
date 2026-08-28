#!/usr/bin/env sh
# EP-021 M3 e2e test: full world-memory user-visible flow.
# Runs the real memory pipeline through the real crates (World Brain ->
# World Bible -> Time Machine): observe, supersede, correct with history,
# continuity export, snapshot, approval-gated restore, observer-only
# surfaces.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml \
  --example e2e_world_memory_flow 2>&1 | tee /tmp/e2e_world_memory_flow.log
grep -q "E2E world memory: ok" /tmp/e2e_world_memory_flow.log || fail "rust world-memory e2e"

echo "e2e EP-021 M3 world-memory: ok"
