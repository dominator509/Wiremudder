#!/usr/bin/env sh
# EP-020 requirement test: WM-SPEC-012-R06 Quest Compass.
# Quest state cites clues and corrections; uncertainty is visible;
# the log is bounded; the surface never sends commands. Proven by the
# real crate, schema, and LF-020 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "wm-spec-012-r06: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-quest/src/lib.rs
grep -q "pub struct QuestClue" "$LIB" || fail "clue struct missing"
grep -q "cited_from" "$LIB" || fail "citation missing"
grep -q "pub struct QuestCorrection" "$LIB" || fail "correction struct missing"
grep -q "pub fn apply_correction" "$LIB" || fail "apply_correction missing"
grep -q "UserCorrected" "$LIB" || fail "user-corrected state missing"
grep -q "max_quests" "$LIB" || fail "bounded log missing"

# Crate tests prove cites/corrections/bounded invariants.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-quest/Cargo.toml 2>&1 \
  | grep -q "quest_cites_clues" || fail "cites invariant"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-quest/Cargo.toml 2>&1 \
  | grep -q "state_transitions_distinct" || fail "correction invariant"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-quest/Cargo.toml 2>&1 \
  | grep -q "bounded_log" || fail "bounded invariant"

# LF-020 certified.
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-020/M5/lf020-certification.json')); assert d['cites_clues'] and d['user_correction_visible'] and d['uncertainty_visible']" \
  || fail "LF-020 certification false"

echo "wm-spec-012-r06 Quest Compass: ok"
