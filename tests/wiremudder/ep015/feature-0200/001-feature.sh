#!/usr/bin/env sh
# EP-015 M5 feature test: WM-FEAT-0200 via the real crate probe.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example feature_probe -- "WM-FEAT-0200" > /tmp/wm-ep015-WM-FEAT-0200.txt 2>/dev/null \
  || fail "probe WM-FEAT-0200"

grep -q "WM-FEAT-0200: ok" /tmp/wm-ep015-WM-FEAT-0200.txt || fail "WM-FEAT-0200 behavior"
rm -f /tmp/wm-ep015-WM-FEAT-0200.txt

echo "feature WM-FEAT-0200: ok"
