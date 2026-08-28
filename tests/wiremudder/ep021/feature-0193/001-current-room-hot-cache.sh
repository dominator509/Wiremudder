#!/usr/bin/env sh
# EP-021 M5 feature test: WM-FEAT-0193 current-room hot cache.
# Hot current state is separate from durable memory (SPEC-012-R03).
# Proven by real crate surface and LF-021 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0193: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-world-brain/src/lib.rs
grep -q "set_hot_room" "$LIB" || fail "hot cache setter missing"
grep -q "hot_room" "$LIB" || fail "hot cache getter missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "hot_state_separate_from_durable" || fail "hot/durable invariant"

[ -f .agent/state/evidence/EP-021/M5/lf021-certification.json ] || fail "LF-021 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-021/M5/lf021-certification.json')); assert d['hot_durable_separate']" \
  || fail "LF-021 hot cache certification false"

echo "feature-0193 current-room hot cache: ok"
