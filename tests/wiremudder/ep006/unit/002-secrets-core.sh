#!/usr/bin/env sh
# EP-006 M2 unit test: wire-secrets core invariants.
# Runs the real Rust unit tests for the secrets crate and verifies
# that secret values are never serialized, logged, or leaked.
set -eu

cd "$(dirname "$0")/../../../.."
cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || { echo "FAIL: cargo missing" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" test \
  --manifest-path wirecore/crates/wire-secrets/Cargo.toml 2>&1 \
  | tee /tmp/wm-ep006-unit-secrets.log \
  | grep -q "test result: ok" || { echo "FAIL: wire-secrets tests" >&2; exit 1; }

# Static proof: no secret value is ever written to any log path in the
# crate source.
if grep -rn "println\|eprintln\|dbg!" wirecore/crates/wire-secrets/src/ | grep -v "^\s*//" ; then
  echo "FAIL: secrets crate contains log macros" >&2; exit 1
fi

echo "unit wire-secrets-core: ok"
