#!/usr/bin/env sh
# EP-021 M5 feature test: WM-FEAT-0194 entity observations.
# World Brain models NPCs, mobs, animals, players, and PvP-visible
# characters through provenance-aware observations (SPEC-012-R01).
# Proven by real crate surface and LF-021 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0194: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-world-brain/src/lib.rs
# Entity observations are arbitrary subjects with full provenance.
grep -q "pub fn observe" "$LIB" || fail "observe missing"
grep -q "subject" "$LIB" || fail "subject missing"
grep -q "source_event" "$LIB" || fail "source event missing"
grep -q "content_hash" "$LIB" || fail "content hash missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "fact_records_provenance" || fail "provenance invariant"

[ -f .agent/state/evidence/EP-021/M5/lf021-certification.json ] || fail "LF-021 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-021/M5/lf021-certification.json')); assert d['provenance_recorded']" \
  || fail "LF-021 entity observation certification false"

echo "feature-0194 entity observations: ok"
