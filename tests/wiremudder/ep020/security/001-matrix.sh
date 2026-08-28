#!/usr/bin/env sh
# EP-020 M4 security test: prompt injection cannot act, secrets are
# redacted (full tokens, repeated), no command path, uncertainty visible.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-narrator/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep020_security.log
grep -q "security matrix: ok" /tmp/ep020_security.log || fail "security matrix"

# Static: no secrets in assistance schemas.
for f in schemas/wiremudder/assistance/*.json; do
  if grep -qiE "sk-[A-Za-z0-9]|sbp_|password *= *[A-Za-z0-9]|api[_-]?key *= *[A-Za-z0-9]" "$f"; then
    fail "secret-shaped token in schema $f"
  fi
done

# Static: no command path on the pane boundary.
HDR=src/wiremudder/ui/assistance/assistance_boundary.h
grep -q "canSendCommand() const { return false; }" "$HDR" || fail "pane has command path"

echo "security EP-020 M4 matrix: ok"
