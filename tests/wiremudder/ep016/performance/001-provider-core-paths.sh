#!/usr/bin/env sh
# EP-016 M4 performance: release-build core-path latency against budgets.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo build --quiet --release \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example provider_bench 2>&1 | tail -3

CARGO_TARGET_DIR="$PWD/wirecore/target" ./wirecore/target/release/examples/provider_bench \
  > /tmp/wm-ep016-perf.txt 2>&1 || { cat /tmp/wm-ep016-perf.txt; fail "provider_bench"; }

for step in redact route-10k parse-response build-payload; do
  grep -q "PERF $step:" /tmp/wm-ep016-perf.txt || fail "perf step $step missing"
done
grep -q "PERF_MATRIX_DONE" /tmp/wm-ep016-perf.txt || fail "missing done sentinel"

echo "performance EP-016 M4 provider-core-paths: ok"
