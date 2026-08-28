#!/usr/bin/env sh
# LF-018 live-fire: soul-agent-permission.
# Real controlled outcome for Soul, Agent Council, Skills, and Memory
# Permissions: the real crates prove that a Soul cannot override policy,
# memory access is denied by default, skills require provenance + evaluation
# to enable, the council requires policy permission and records disagreement,
# no agent can grant itself authority, safe user messages leak nothing, and
# the Soul pane is a passive observer that preserves manual text gameplay.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-018: FAIL - $1" >&2; exit 1; }

EVIDENCE=.agent/state/evidence/EP-018/M5/lf018-certification.json

# 1. Run the live permission fire (real crates, real schemas, real boundary).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-agents/Cargo.toml \
  --example live_soul_permission 2>&1 | tee /tmp/lf018_live.log
grep -q "LF-018 live: ok" /tmp/lf018_live.log || fail "live soul permission run"

# 2. Certification evidence is written with real measured values.
[ -f "$EVIDENCE" ] || fail "missing certification evidence $EVIDENCE"
python3 - "$EVIDENCE" <<'PY' || fail "invalid certification evidence"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["soul_denials"] >= 12, "soul policy override attempts must be denied"
assert "instruction-layer" in d["policy_domains_guarded"], "injection must be guarded"
assert d["studio_audit_records_denials"] is True
assert d["memory_pairs_denied_by_default"] == d["memory_pairs_total"] - 1
assert d["memory_deny_by_default"] is True
assert d["skill_pending_not_enabled"] is True
assert d["skill_evaluated_enabled"] is True
assert d["council_denied_without_permission"] is True
assert d["council_budget_enforced"] is True
assert d["council_disagreement_recorded"] is True
assert d["no_self_grant_authority"] is True
assert d["safe_message_leak_count"] == 0, "safe messages must not leak internals"
assert d["pane_passive_observer"] is True
assert d["pane_no_command_path"] is True
assert d["council_budget_usd_micros"] == 42
PY

echo "LF-018: ok"
