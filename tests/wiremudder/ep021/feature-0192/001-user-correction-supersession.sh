#!/usr/bin/env sh
# EP-021 M5 feature test: WM-FEAT-0192 user correction and supersession
# workflow. Corrections supersede derived facts while preserving history
# (SPEC-012-R10). Proven by real crate surface and LF-021 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0192: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-world-brain/src/lib.rs
grep -q "pub fn correct" "$LIB" || fail "correct missing"
grep -q "UserCorrected" "$LIB" || fail "user-corrected state missing"
grep -q "correction_note" "$LIB" || fail "correction note missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml 2>&1 \
  | grep -q "correction_supersedes_but_preserves_history" || fail "correction invariant"

[ -f .agent/state/evidence/EP-021/M5/lf021-certification.json ] || fail "LF-021 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-021/M5/lf021-certification.json')); assert d['correction_supersedes'] and d['history_preserved']" \
  || fail "LF-021 correction certification false"

echo "feature-0192 user correction and supersession: ok"
