#!/usr/bin/env sh
# EP-021 M4 security test: prompt injection cannot act, private facts
# stay scoped, secrets never export, restore requires approval.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml \
  --example security_matrix 2>&1 | tee /tmp/ep021_security.log
grep -q "security matrix: ok" /tmp/ep021_security.log || fail "security matrix"

# Static: no secrets in memory schemas.
for f in schemas/wiremudder/memory/*.json; do
  if grep -qiE "sk-[A-Za-z0-9]|sbp_|password *= *[A-Za-z0-9]|api[_-]?key *= *[A-Za-z0-9]" "$f"; then
    fail "secret-shaped token in schema $f"
  fi
done

# Static: every crate surface is observer-only.
for lib in wirecore/crates/wire-world-brain/src/lib.rs \
           wirecore/crates/wire-world-bible/src/lib.rs \
           wirecore/crates/wire-time-machine/src/lib.rs; do
  grep -q "can_send_command" "$lib" || fail "no-command invariant missing in $lib"
done

echo "security EP-021 M4 matrix: ok"
