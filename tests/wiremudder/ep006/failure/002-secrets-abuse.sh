#!/usr/bin/env sh
# EP-006 M4 failure test: secrets vault abuse cases.
# Invalid ids, missing operations, and overlapping secret values must
# error or redact deterministically (real wire-secrets crate).
set -eu

cd "$(dirname "$0")/../../../.."
cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)

CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" test \
  --manifest-path wirecore/crates/wire-secrets/Cargo.toml abuse_ 2>&1 \
  | tee /tmp/wm-ep006-m4-sec-abuse.log \
  | grep -q "test result: ok" || { echo "FAIL: secrets abuse tests" >&2; exit 1; }
echo "failure secrets-abuse: ok"
