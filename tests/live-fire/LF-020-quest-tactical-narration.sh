#!/usr/bin/env sh
# LF-020 live-fire: quest-tactical-narration.
# Real controlled outcome for Quest Compass, Tactical HUD, and Personal
# Narrator: cited quest tracking with visible uncertainty, user
# corrections, bounded tactical snapshots, narrator summaries that
# disclose source and redact secrets, load shedding, no command path,
# and preserved manual text gameplay.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-020: FAIL - $1" >&2; exit 1; }

EVIDENCE=.agent/state/evidence/EP-020/M5/lf020-certification.json

# 1. Run the live assistance fire (real crates, real schemas, real pane).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-narrator/Cargo.toml \
  --example live_assistance 2>&1 | tee /tmp/lf020_live.log
grep -q "LF-020 live: ok" /tmp/lf020_live.log || fail "live assistance run"

# 2. Certification evidence is written with real measured values.
[ -f "$EVIDENCE" ] || fail "missing certification evidence $EVIDENCE"
python3 - "$EVIDENCE" <<'PY' || fail "invalid certification evidence"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["cites_clues"] is True
assert d["user_correction_visible"] is True
assert d["uncertainty_visible"] is True
assert d["bounded_snapshot"] is True
assert d["oversized_rejected"] is True
assert d["source_disclosed"] is True
assert d["secrets_redacted"] is True
assert d["load_shedding"] is True
assert d["hud_no_command"] is True
assert d["pane_passive"] is True
assert d["pane_no_command_path"] is True
PY

echo "LF-020: ok"
