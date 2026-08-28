#!/usr/bin/env sh
# EP-027 M4 security test: the real security matrix must run through
# the production wire-help crate and prove every required security
# boundary (SPEC-022, SPEC-018).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "security: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep027_security_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet \
  --manifest-path wirecore/crates/wire-help/Cargo.toml \
  --example security_matrix >"$out" 2>&1 || {
  cat "$out" >&2
  fail "security matrix did not run"
}

for i in 1 2 3 4 5; do
  grep -q "security-$i " "$out" || fail "security proof $i missing"
done
grep -q "security matrix EP-027: ok" "$out" || fail "security matrix not ok"

echo "security EP-027 matrix: ok"
