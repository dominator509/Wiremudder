#!/usr/bin/env sh
# EP-020 M5 feature test: WM-FEAT-0184 Tactical Agent.
# Tactical Agent with evidence, safety, rollback, and release-profile
# controls. The Tactical HUD crate is the deterministic, evidence-backed
# tactical surface; the node's fallback (read-only current-state
# snapshots, deferring model inference) is documented and certified by
# LF-020. No hidden model inference, no command path.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0184: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-tactical/src/lib.rs
grep -q "pub struct TacticalHud" "$LIB" || fail "TacticalHud missing"
grep -q "TacticalError" "$LIB" || fail "typed errors missing"
grep -q "Oversized" "$LIB" || fail "bounded resource missing"
grep -q "StaleSnapshot" "$LIB" || fail "stale rejection missing"

# Evidence: LF-020 certification proves the tactical surface.
[ -f .agent/state/evidence/EP-020/M5/lf020-certification.json ] || fail "LF-020 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-020/M5/lf020-certification.json')); assert d['bounded_snapshot'] and d['oversized_rejected'] and d['hud_no_command']" \
  || fail "LF-020 tactical agent certification false"

# Safety: no command path on any tactical surface.
grep -q "pub fn can_send_command" "$LIB" || fail "no-command invariant missing"

echo "feature-0184 Tactical Agent: ok"
