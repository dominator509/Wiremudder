#!/usr/bin/env sh
# EP-019 M4 performance test: autopilot engine path latency fixture.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --release --quiet \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml \
  --example perf_autopilot 2>&1 | tee /tmp/ep019_perf.log
grep -q "perf fixture: ok" /tmp/ep019_perf.log || fail "perf fixture"
grep -E "^perf:" /tmp/ep019_perf.log | head -1

echo "performance EP-019 M4 engine-path: ok"
