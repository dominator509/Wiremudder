#!/usr/bin/env sh
# EP-027 M4 failure test: the real controlled failure matrix must run
# through the production wire-help crate and prove every required
# failure proof from the node contract.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"

out=$(mktemp /tmp/ep027_failure_XXXX.log)
CARGO_TARGET_DIR="$PWD/wirecore/target" "$cargo_bin" run --quiet \
  --manifest-path wirecore/crates/wire-help/Cargo.toml \
  --example failure_matrix >"$out" 2>&1 || {
  cat "$out" >&2
  fail "failure matrix did not run"
}

for i in 1 2 3 4 5 6 7 8; do
  grep -q "failure-$i " "$out" || fail "failure proof $i missing"
done
grep -q "failure matrix EP-027: ok" "$out" || fail "failure matrix not ok"

echo "failure EP-027 matrix: ok"
