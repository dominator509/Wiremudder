#!/usr/bin/env sh
# LF-019 live-fire: guarded-autopilot-confirmation.
# Real controlled outcome for Guarded Autopilot: the real crate proves
# that the autopilot is off by default, every action is a visible bounded
# Action Proposal, destructive actions require explicit confirmation,
# rate limits are deterministic, stale state pauses, emergency stop
# cancels immediately, the audit is complete, the pane is passive with no
# command path, and manual text gameplay is preserved.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-019: FAIL - $1" >&2; exit 1; }

EVIDENCE=.agent/state/evidence/EP-019/M5/lf019-certification.json

# 1. Run the live confirmation fire (real crates, real schemas, real pane).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-autopilot/Cargo.toml \
  --example live_autopilot 2>&1 | tee /tmp/lf019_live.log
grep -q "LF-019 live: ok" /tmp/lf019_live.log || fail "live autopilot run"

# 2. Certification evidence is written with real measured values.
[ -f "$EVIDENCE" ] || fail "missing certification evidence $EVIDENCE"
python3 - "$EVIDENCE" <<'PY' || fail "invalid certification evidence"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["off_by_default"] is True
assert d["enabled_for_profile"] is True
assert d["visible_before_send"] is True
assert d["destructive_requires_confirmation"] is True
assert d["confirmed_send_result"] == "sent-confirmed"
assert d["rate_limited"] is True
assert d["stale_pause"] is True
assert d["emergency_stop_cancelled"] is True
assert d["emergency_stop_engaged"] is True
assert d["audit_complete"] is True
assert d["audited_send_count"] >= 2
assert d["no_hidden_send"] is True
assert d["pane_passive"] is True
assert d["pane_no_command_path"] is True
PY

echo "LF-019: ok"
