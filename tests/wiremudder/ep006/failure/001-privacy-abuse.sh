#!/usr/bin/env sh
# EP-006 M4 failure test: privacy abuse cases.
# Malformed receipts, invisible overrides, and overlapping redaction
# must be rejected or deterministic (real wire-privacy crate).
set -eu

cd "$(dirname "$0")/../../../.."
cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)

CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" test \
  --manifest-path wirecore/crates/wire-privacy/Cargo.toml abuse_ 2>&1 \
  | tee /tmp/wm-ep006-m4-priv-abuse.log \
  | grep -q "test result: ok" || { echo "FAIL: privacy abuse tests" >&2; exit 1; }
echo "failure privacy-abuse: ok"
