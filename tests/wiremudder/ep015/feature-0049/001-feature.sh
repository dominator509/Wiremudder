#!/usr/bin/env sh
# EP-015 M5 feature test: WM-FEAT-0049 via the real crate probe.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-token-budget/Cargo.toml \
  --example feature_probe -- "WM-FEAT-0049" > /tmp/wm-ep015-WM-FEAT-0049.txt 2>/dev/null \
  || fail "probe WM-FEAT-0049"

grep -q "WM-FEAT-0049: ok" /tmp/wm-ep015-WM-FEAT-0049.txt || fail "WM-FEAT-0049 behavior"
rm -f /tmp/wm-ep015-WM-FEAT-0049.txt

echo "feature WM-FEAT-0049: ok"
