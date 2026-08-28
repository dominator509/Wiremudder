#!/usr/bin/env sh
# EP-017 M4 security test: prompt injection, secret leakage, permission
# denial, redaction integrity, and soul policy precedence.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-copilot/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep017_security.log
grep -q "security matrix: ok" /tmp/ep017_security.log || fail "security matrix"

# Static invariants (independent of the Rust run).
# 1. No secrets in schemas.
for f in schemas/wiremudder/copilot/*.json; do
  if grep -qiE "sk-[A-Za-z0-9]|sbp_|password *= *[A-Za-z0-9]|api[_-]?key *= *[A-Za-z0-9]" "$f"; then
    fail "secret-shaped token in schema $f"
  fi
done

# 2. Soul immutability domains are declared.
grep -q "SOUL_IMMUTABLE_POLICY" wirecore/crates/wire-copilot/src/lib.rs \
  || fail "immutable policy domains not declared"
for d in security privacy routing package updater emergency-stop; do
  grep -q "$d" wirecore/crates/wire-copilot/src/lib.rs || fail "missing policy domain $d"
done

echo "security EP-017 M4 matrix: ok"
