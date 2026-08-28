#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-020-R08 — package, model, audio,
# renderer, help, and provider assets are optional and never silently
# bundled or enabled.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

grep -q "optional_lanes_require_consent" security/wiremudder/src/lanes.rs \
  || fail "consent policy missing"

cargo_bin=$(command -v cargo || echo /root/.cargo/bin/cargo)
[ -x "$cargo_bin" ] || fail "cargo missing"
export CARGO_TARGET_DIR="$PWD/wirecore/target"

out=$(mktemp /tmp/ep033_r0208_XXXX.log)
trap 'rm -f "$out"' EXIT

"$cargo_bin" run --quiet --release --manifest-path security/wiremudder/Cargo.toml -- lanes >"$out" 2>&1 \
  || fail "lanes failed"
enabled_optional=$(grep -c 'optional=true enabled=true' "$out" || true)
[ "$enabled_optional" -eq 0 ] || fail "optional asset silently enabled"

echo "requirement WM-SPEC-020-R08: ok"
