#!/usr/bin/env sh
# EP-023 M4 performance test: measured real paths, hardware/workload
# header, distributions (p50/p95/max), and SPEC-004 budget assertion.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-headless/Cargo.toml \
  --example perf_fixture 2>&1 | tee /tmp/ep023_perf_fixture.log

grep -q "^perf hardware:" /tmp/ep023_perf_fixture.log || fail "missing hardware header"
grep -q "perf headless profile:" /tmp/ep023_perf_fixture.log || fail "missing headless profile"
grep -q "perf fixture: 4 paths measured, all within 5ms budget" /tmp/ep023_perf_fixture.log \
  || fail "perf fixture did not complete within budget"

echo "performance EP-023 M4 perf-fixture: ok"
