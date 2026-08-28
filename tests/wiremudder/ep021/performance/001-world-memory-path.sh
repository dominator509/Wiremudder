#!/usr/bin/env sh
# EP-021 M4 performance test: world-memory stack latency fixture.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --release --quiet \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml \
  --example perf_world_memory 2>&1 | tee /tmp/ep021_perf.log
grep -q "perf fixture: ok" /tmp/ep021_perf.log || fail "perf fixture"
grep -E "^perf:" /tmp/ep021_perf.log | head -1

echo "performance EP-021 M4 world-memory-path: ok"
