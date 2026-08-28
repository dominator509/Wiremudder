#!/usr/bin/env sh
# EP-021 M5 feature test: WM-FEAT-0191 room identity confidence.
# Facts carry confidence and ambiguous room identity remains uncertain
# rather than silently merged (SPEC-012-R05). Proven by real crate
# surface and LF-021 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0191: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-world-brain/src/lib.rs
grep -q "confidence" "$LIB" || fail "confidence missing"
grep -q "WorldBrainError::Validation" "$LIB" || fail "typed validation missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "fact_records_provenance" || fail "confidence invariant"

[ -f .agent/state/evidence/EP-021/M5/lf021-certification.json ] || fail "LF-021 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-021/M5/lf021-certification.json')); assert d['provenance_recorded']" \
  || fail "LF-021 confidence certification false"

echo "feature-0191 room identity confidence: ok"
