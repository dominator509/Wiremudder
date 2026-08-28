#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-022-R08 — threat models include data
# flow, assets, actors, entry points, trust boundaries, misuse cases,
# mitigations, residual risk, and verification.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

out=$(mktemp /tmp/ep033_r0228_XXXX.log)
trap 'rm -f "$out"' EXIT

"$cargo_bin" run --quiet --release --manifest-path security/wiremudder/Cargo.toml -- \
  threat-model tests/wiremudder/ep033/fixtures/threat-model-session-bridge.json >"$out" 2>&1 \
  || { cat "$out" >&2; fail "threat model failed"; }
grep -q "threat-model: ok" "$out" || fail "threat model sentinel missing"

echo "requirement WM-SPEC-022-R08: ok"
