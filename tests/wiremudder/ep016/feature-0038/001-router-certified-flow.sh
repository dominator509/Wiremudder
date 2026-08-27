#!/usr/bin/env sh
# WM-FEAT-0038: AI Provider Router.
# Proves deterministic routing, privacy/budget gating, explicit degradation,
# and that the certified local route is selected from the shipped config.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0038: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example e2e_provider_flow > /tmp/wm-f0038.txt 2>&1 \
  || { cat /tmp/wm-f0038.txt; fail "e2e_provider_flow"; }

grep -q "E2E route: ok (ollama-local" /tmp/wm-f0038.txt || fail "certified local route selected"
grep -q "E2E redact: ok" /tmp/wm-f0038.txt || fail "redaction"
grep -q "E2E gameplay-after-failure: ok" /tmp/wm-f0038.txt || fail "gameplay preserved"

# Router unit invariants (determinism, gating, degradation, evaluation).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml 2>&1 \
  | grep -q "21 passed" || fail "router unit invariants"

echo "feature WM-FEAT-0038: ok"
