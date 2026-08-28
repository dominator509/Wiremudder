#!/usr/bin/env sh
# EP-019 M4 security test: no hidden send, confirmation not bypassable,
# narrow allowlist, no self-authority, complete audit, safe messages.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep019_security.log
grep -q "security matrix: ok" /tmp/ep019_security.log || fail "security matrix"

# Static: no secrets in autopilot schemas.
for f in schemas/wiremudder/autopilot/*.json; do
  if grep -qiE "sk-[A-Za-z0-9]|sbp_|password *= *[A-Za-z0-9]|api[_-]?key *= *[A-Za-z0-9]" "$f"; then
    fail "secret-shaped token in schema $f"
  fi
done

echo "security EP-019 M4 matrix: ok"
