#!/usr/bin/env sh
# EP-018 M4 performance test: soul/agents engine path latency fixture.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --release --quiet \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml \
  --example perf_agents 2>&1 | tee /tmp/ep018_perf.log
grep -q "perf fixture: ok" /tmp/ep018_perf.log || fail "perf fixture"
grep -E "^perf:" /tmp/ep018_perf.log | head -1

echo "performance EP-018 M4 engine-path: ok"
