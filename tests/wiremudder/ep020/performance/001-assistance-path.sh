#!/usr/bin/env sh
# EP-020 M4 performance test: assistance stack latency fixture.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --release --quiet \
  --manifest-path wirecore/crates/wire-narrator/Cargo.toml \
  --example perf_assistance 2>&1 | tee /tmp/ep020_perf.log
grep -q "perf fixture: ok" /tmp/ep020_perf.log || fail "perf fixture"
grep -E "^perf:" /tmp/ep020_perf.log | head -1

echo "performance EP-020 M4 assistance-path: ok"
