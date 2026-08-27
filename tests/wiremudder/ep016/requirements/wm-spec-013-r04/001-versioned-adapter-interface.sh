#!/usr/bin/env sh
# WM-SPEC-013-R04: provider adapters expose one versioned interface for
# local and remote models and normalize streaming, cancellation, usage,
# errors, health, and capability metadata.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r04: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-provider-adapters/Cargo.toml 2>&1 \
  | grep -q "19 passed" || fail "adapter interface tests"

# The trait is the single versioned interface; capability metadata is
# normalized and schema-versioned.
grep -q "pub trait ProviderAdapter" wirecore/crates/wire-provider-adapters/src/lib.rs \
  || fail "missing ProviderAdapter trait"
grep -q "ADAPTER_SCHEMA_VERSION: u32 = 1" wirecore/crates/wire-provider-adapters/src/lib.rs \
  || fail "schema version drift"
python3 -c "import json; json.load(open('schemas/wiremudder/ai/provider-capability-v1.json'))" \
  || fail "capability schema invalid"

echo "req WM-SPEC-013-R04: ok"
