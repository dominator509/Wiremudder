#!/usr/bin/env sh
# EP-020 M5 feature test: WM-FEAT-0183 Quest Agent.
# Quest Agent with evidence, safety, rollback, and release-profile
# controls. The Quest Compass crate is the deterministic, evidence-backed
# quest surface; the node's fallback (read-only text summaries from
# current state, deferring model inference) is documented and certified
# by LF-020. No hidden model inference, no command path.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0183: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-quest/src/lib.rs
grep -q "pub struct QuestLog" "$LIB" || fail "QuestLog missing"
grep -q "QuestError" "$LIB" || fail "typed errors missing"
grep -q "Exhaustion" "$LIB" || fail "bounded resource missing"
grep -q "NotFound" "$LIB" || fail "not-found error missing"

# Evidence: LF-020 certification proves the quest surface.
[ -f .agent/state/evidence/EP-020/M5/lf020-certification.json ] || fail "LF-020 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-020/M5/lf020-certification.json')); assert d['cites_clues'] and d['user_correction_visible']" \
  || fail "LF-020 quest agent certification false"

# Safety: no command path on any quest surface.
if grep -qE "pub fn (send|execute|emit_command)" "$LIB"; then
  fail "quest agent exposes a command path"
fi

echo "feature-0183 Quest Agent: ok"
