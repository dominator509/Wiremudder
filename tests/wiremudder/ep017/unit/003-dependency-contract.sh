#!/usr/bin/env sh
# EP-017 M2 unit test: the copilot crate compiles against the EP-015
# context capsule and EP-016 router surfaces (dependency contract).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

# The copilot consumes EP-015 capsules and routes through EP-016.
grep -q "wire-context" wirecore/crates/wire-copilot/Cargo.toml \
  || fail "wire-copilot missing wire-context dependency"
grep -q "wire-ai-router" wirecore/crates/wire-copilot/Cargo.toml \
  || fail "wire-copilot missing wire-ai-router dependency"
grep -q "wire-privacy" wirecore/crates/wire-copilot/Cargo.toml \
  || fail "wire-copilot missing wire-privacy dependency"
grep -q "wire-token-budget" wirecore/crates/wire-copilot/Cargo.toml \
  || fail "wire-copilot missing wire-token-budget dependency"

echo "unit EP-017 M2 dependency-contract: ok"
