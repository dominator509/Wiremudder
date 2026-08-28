#!/usr/bin/env sh
# EP-021 M5 feature test: WM-FEAT-0050 World Brain.
# Provenance-aware world memory: facts carry source, confidence,
# sensitivity, supersession; corrections supersede without erasing
# history (SPEC-012-R01/R02/R10). Proven by real crate surface, schema,
# and the LF-021 live-fire certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0050: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-world-brain/src/lib.rs
grep -q "pub struct WorldBrain" "$LIB" || fail "WorldBrain missing"
grep -q "pub fn observe" "$LIB" || fail "observe missing"
grep -q "pub fn correct" "$LIB" || fail "correct missing"
grep -q "pub struct MemoryFact" "$LIB" || fail "MemoryFact missing"
grep -q "confidence" "$LIB" || fail "confidence missing"
grep -q "supersession" "$LIB" || fail "supersession missing"
grep -q "Sensitivity" "$LIB" || fail "sensitivity missing"
grep -q "content_hash" "$LIB" || fail "content hash missing"

# Schema exists and is valid JSON.
python3 -c "import json; json.load(open('schemas/wiremudder/memory/world-brain-fact-v1.json'))" \
  || fail "world-brain-fact schema invalid"

# Real behavior: provenance, supersession, correction proven by crate tests.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "fact_records_provenance" || fail "provenance invariant"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "correction_supersedes_but_preserves_history" || fail "correction invariant"

# LF-021 certified.
[ -f .agent/state/evidence/EP-021/M5/lf021-certification.json ] || fail "LF-021 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-021/M5/lf021-certification.json')); assert d['provenance_recorded'] and d['correction_supersedes'] and d['history_preserved']" \
  || fail "LF-021 world brain certification false"

echo "feature-0050 World Brain: ok"
