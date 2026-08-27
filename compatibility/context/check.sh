#!/usr/bin/env sh
# EP-015 M3 compatibility oracle: corpus of raw game lines must map to
# the exact typed-event tags (deterministic, no AI, no heuristics drift).
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "compat: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-context/Cargo.toml \
  --example compat_corpus -- "$PWD/compatibility/context/corpus-v1.json" \
  > /tmp/wm-ep015-compat.txt 2>/dev/null || fail "compat runner"

grep -q "compat-corpus: ok" /tmp/wm-ep015-compat.txt || fail "corpus divergence"
rm -f /tmp/wm-ep015-compat.txt

echo "compatibility EP-015 M3 context: ok"
