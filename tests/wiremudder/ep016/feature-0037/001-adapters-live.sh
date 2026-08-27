#!/usr/bin/env sh
# WM-FEAT-0037: local and remote AI provider adapters.
# Proves the real adapter surface: versioned capabilities, live completion,
# streaming, usage, redaction, and the disabled remote adapter.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0037: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example integration_flow > /tmp/wm-f0037.txt 2>&1 \
  || { cat /tmp/wm-f0037.txt; fail "integration_flow"; }

grep -q "STATE ready: ok" /tmp/wm-f0037.txt || fail "adapter capability metadata"
grep -q "STATE privacy: ok" /tmp/wm-f0037.txt || fail "redaction"
grep -q "STATE disabled: ok" /tmp/wm-f0037.txt || fail "disabled remote adapter"
grep -q "LIVE complete: ok" /tmp/wm-f0037.txt || fail "live completion"
grep -q "LIVE stream: ok" /tmp/wm-f0037.txt || fail "live streaming"
grep -q "LIVE usage: ok" /tmp/wm-f0037.txt || fail "usage normalization"

echo "feature WM-FEAT-0037: ok"
