#!/usr/bin/env sh
# EP-006 M2 unit test: wire-privacy core invariants.
# Runs the real Rust unit tests for the privacy crate (egress policy,
# consent registry, redaction engine) and proves the denial-first
# posture end to end.
set -eu

cd "$(dirname "$0")/../../../.."
cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || { echo "FAIL: cargo missing" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" test \
  --manifest-path wirecore/crates/wire-privacy/Cargo.toml 2>&1 \
  | tee /tmp/wm-ep006-unit-privacy.log \
  | grep -q "test result: ok" || { echo "FAIL: wire-privacy tests" >&2; exit 1; }

echo "unit wire-privacy-core: ok"
