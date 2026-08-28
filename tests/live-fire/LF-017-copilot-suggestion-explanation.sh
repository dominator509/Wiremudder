#!/usr/bin/env sh
# LF-017 live-fire: copilot suggestion and explanation.
# Real controlled outcome for Player Copilot, Explanations, and Confidence:
# a real game-line distillation (EP-015) routes through EP-016 and completes
# against the live local provider (Ollama 127.0.0.1:11434, certified by
# LF-016), producing a real suggestion with citations, Why explanation,
# calibrated confidence, and visible disclosures. The degraded path (provider
# down) must preserve manual text gameplay.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-017: FAIL - $1" >&2; exit 1; }

EVIDENCE=.agent/state/evidence/EP-017/M5/lf017-certification.json

# 0. Controlled dependency: the local provider must be reachable.
curl -sf --max-time 5 http://127.0.0.1:11434/api/tags >/dev/null 2>&1 \
  || fail "local provider (Ollama 127.0.0.1:11434) not reachable"

# 1. The shipped config certifies the local route (EP-016 state).
CONFIG=config/wiremudder/providers/routing-policy.example.json
[ -f "$CONFIG" ] || fail "missing routing policy $CONFIG"
python3 - "$CONFIG" <<'PY' || fail "routing policy certification state"
import json, sys
d = json.load(open(sys.argv[1]))
local = [r for r in d["routes"] if r["kind"] == "local"]
assert local and local[0]["certified"] is True, "local route must be certified"
PY

# 2. Run the live copilot fire (real provider call, real engine).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-copilot/Cargo.toml \
  --example live_copilot 2>&1 | tee /tmp/lf017_live.log
grep -q "LF-017 live: ok" /tmp/lf017_live.log || fail "live copilot run"

# 3. Certification evidence is written with real measured values.
[ -f "$EVIDENCE" ] || fail "missing certification evidence $EVIDENCE"
python3 - "$EVIDENCE" <<'PY' || fail "invalid certification evidence"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["provider"] == "ollama"
assert d["model"] == "tinyllama:latest"
assert d["health_ok"] is True
assert d["completion_latency_ms"] > 0
assert d["suggestion_nonempty"] is True
assert d["citations"] >= 1, "suggestion must cite observations"
assert 0.0 < d["confidence"] < 1.0, "confidence must be calibrated and non-authoritative"
assert d["why_nonempty"] is True
assert d["disclosure_context_bytes"] > 0
assert d["privacy_leak_count"] == 0, "no secrets may leak"
assert d["action_proposal_requires_confirmation"] is True or d["action_proposal_present"] is False
assert d["manual_gameplay_preserved"] is True
PY

echo "LF-017: ok"
