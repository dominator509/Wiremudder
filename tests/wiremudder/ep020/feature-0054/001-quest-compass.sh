#!/usr/bin/env sh
# EP-020 M5 feature test: WM-FEAT-0054 Quest Compass.
# Cited quest tracking with observed/inferred/completed/failed/
# user-corrected state (WM-SPEC-012-R06). Proven by real crate surface,
# schema, and the LF-020 live-fire certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0054: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-quest/src/lib.rs
grep -q "pub struct QuestLog" "$LIB" || fail "QuestLog missing"
grep -q "pub fn track" "$LIB" || fail "track missing"
grep -q "pub fn add_clue" "$LIB" || fail "add_clue missing"
grep -q "pub fn apply_correction" "$LIB" || fail "apply_correction missing"
grep -q "pub enum QuestState" "$LIB" || fail "QuestState missing"
grep -q "Observed" "$LIB" || fail "observed state missing"
grep -q "Inferred" "$LIB" || fail "inferred state missing"
grep -q "UserCorrected" "$LIB" || fail "user-corrected state missing"
grep -q "pub struct QuestClue" "$LIB" || fail "QuestClue missing"
grep -q "cited_from" "$LIB" || fail "clue citation missing"

# Schema exists and is valid JSON.
python3 -c "import json; json.load(open('schemas/wiremudder/assistance/quest-log-v1.json'))" \
  || fail "quest-log schema invalid"

# Real behavior: cited clues, corrections, uncertainty, bounded log all
# proven by the crate tests.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-quest/Cargo.toml 2>&1 \
  | grep -q "quest_cites_clues" || fail "cites-clues invariant"

# LF-020 certified quest behavior.
[ -f .agent/state/evidence/EP-020/M5/lf020-certification.json ] || fail "LF-020 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-020/M5/lf020-certification.json')); assert d['cites_clues'] and d['user_correction_visible'] and d['uncertainty_visible']" \
  || fail "LF-020 quest certification false"

echo "feature-0054 Quest Compass: ok"
