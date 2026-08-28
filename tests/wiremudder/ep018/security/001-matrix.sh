#!/usr/bin/env sh
# EP-018 M4 security test: injection, self-grant, provenance, audit.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep018_security.log
grep -q "security matrix: ok" /tmp/ep018_security.log || fail "security matrix"

# Static: no secrets in schemas.
for f in schemas/wiremudder/agents/*.json; do
  if grep -qiE "sk-[A-Za-z0-9]|sbp_|password *= *[A-Za-z0-9]|api[_-]?key *= *[A-Za-z0-9]" "$f"; then
    fail "secret-shaped token in schema $f"
  fi
done

echo "security EP-018 M4 matrix: ok"
