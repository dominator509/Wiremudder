#!/usr/bin/env sh
# EP-023 M3 e2e test: user-visible headless flow through the real crate
# and the real supervisor CLI tool.
# 1. Rust headless e2e flow (real crate, real state).
# 2. Supervisor CLI builds and runs (real tool, real dependencies).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

# 1. Rust headless e2e flow.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-headless/Cargo.toml \
  --example e2e_headless 2>&1 | tee /tmp/e2e_headless_flow.log
grep -q "E2E headless: ok" /tmp/e2e_headless_flow.log || fail "rust headless e2e"

# 2. Supervisor CLI tool: real build, real run.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path tools/wiremudder-supervisor/Cargo.toml 2>&1 | tee /tmp/e2e_supervisor_cli.log
grep -q "supervisor cli: ok" /tmp/e2e_supervisor_cli.log || fail "supervisor CLI run"
grep -q "scheduler fairness: sessions served" /tmp/e2e_supervisor_cli.log || fail "fairness not shown"
grep -q "supervisor: session=" /tmp/e2e_supervisor_cli.log || fail "snapshot not shown"
grep -q "emergency stop: new work denied" /tmp/e2e_supervisor_cli.log || fail "emergency stop not shown"

echo "e2e EP-023 M3 headless-multisession: ok"
