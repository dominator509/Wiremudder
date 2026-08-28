#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-020-R02 — core app, provider adapter,
# context rules, command pack, plugin pack, renderer pack, audio pack, local
# model asset, and help index are separate update lanes.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

out=$(mktemp /tmp/ep033_r0202_XXXX.log)
trap 'rm -f "$out"' EXIT

"$cargo_bin" run --quiet --release --manifest-path security/wiremudder/Cargo.toml -- lanes >"$out" 2>&1 \
  || { cat "$out" >&2; fail "lanes failed"; }

lanes=$(grep -c '^lane ' "$out")
[ "$lanes" -eq 9 ] || fail "expected 9 lanes, got $lanes"
for lane in core-app provider-adapter context-rules command-pack plugin-pack \
            renderer-pack audio-pack local-model-asset help-index; do
  grep -q "lane $lane " "$out" || fail "missing lane $lane"
done

echo "requirement WM-SPEC-020-R02: ok"
