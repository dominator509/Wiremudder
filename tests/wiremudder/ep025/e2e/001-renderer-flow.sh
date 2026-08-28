#!/usr/bin/env sh
# EP-025 M3 e2e test: user-visible renderer flow through the real crate.
# 1. Rust renderer e2e flow (real crate, real state).
# 2. Original licensed assets; complete emit catalog; frame budget;
#    clickable exits; modes; crash-to-text.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

# 1. Rust renderer e2e flow.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-renderer/Cargo.toml \
  --example e2e_renderer 2>&1 | tee /tmp/e2e_renderer_flow.log
grep -q "E2E renderer: ok" /tmp/e2e_renderer_flow.log || fail "rust renderer e2e"

# 2. Acceptance obligations visible in real output.
grep -q "original licensed pack accepted" /tmp/e2e_renderer_flow.log || fail "original assets not shown"
grep -q "complete catalog" /tmp/e2e_renderer_flow.log || fail "emit catalog not shown"
grep -q "frame budget" /tmp/e2e_renderer_flow.log || fail "frame budget not shown"
grep -q "exits: visible exit proposes" /tmp/e2e_renderer_flow.log || fail "clickable exits not shown"
grep -q "static freeze and text-only fallback" /tmp/e2e_renderer_flow.log || fail "fallback not shown"
grep -q "renderer degrades to text" /tmp/e2e_renderer_flow.log || fail "crash-to-text not shown"

echo "e2e EP-025 M3 renderer-flow: ok"
