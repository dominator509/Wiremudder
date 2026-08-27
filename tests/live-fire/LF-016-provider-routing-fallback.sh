#!/usr/bin/env sh
# LF-016 live-fire: provider routing and fallback.
# Real controlled outcome for AI Provider Router and Adapters: certifies the
# real local provider path (Ollama at 127.0.0.1:11434), proves routing,
# redaction, streaming, cancellation, fallback, and that provider failure
# preserves manual text gameplay. The certification evidence file carries
# real measured values from a live run.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-016: FAIL - $1" >&2; exit 1; }

EVIDENCE=.agent/state/evidence/EP-016/M5/lf016-certification.json
CONFIG=config/wiremudder/providers/routing-policy.example.json

# 0. Controlled dependency: the local provider must be reachable.
curl -sf --max-time 5 http://127.0.0.1:11434/api/tags >/dev/null 2>&1 \
  || fail "local provider (Ollama 127.0.0.1:11434) not reachable"

# 1. Certification evidence exists with real measured values.
[ -f "$EVIDENCE" ] || fail "missing certification evidence $EVIDENCE"
python3 - "$EVIDENCE" <<'PY' || fail "invalid certification evidence"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["provider"] == "ollama"
assert d["certified"] is True
assert d["health_ok"] is True
assert d["completion_latency_ms"] > 0
assert d["stream_chunks"] > 0
assert d["privacy_leak_count"] == 0
PY

# 2. The shipped routing policy certifies the local route and keeps the
#    remote placeholder disabled (no silent remote fallback).
python3 - "$CONFIG" <<'PY' || fail "routing policy certification state"
import json, sys
d = json.load(open(sys.argv[1]))
local = [r for r in d["routes"] if r["kind"] == "local"]
remote = [r for r in d["routes"] if r["kind"] == "remote"]
assert local and local[0]["certified"] is True, "local route must be certified"
assert remote and remote[0]["certified"] is False, "remote must stay uncertified"
assert remote[0]["configured"] is False, "remote must stay unconfigured"
PY

# 3. Real integration: live completion, streaming, usage, all states.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example integration_flow > /tmp/wm-lf016-integration.txt 2>&1 \
  || { cat /tmp/wm-lf016-integration.txt; fail "integration_flow"; }
grep -q "LIVE complete: ok" /tmp/wm-lf016-integration.txt || fail "live completion"
grep -q "LIVE stream: ok" /tmp/wm-lf016-integration.txt || fail "live streaming"
grep -q "LIVE usage: ok" /tmp/wm-lf016-integration.txt || fail "live usage"
grep -q "INTEGRATION_FLOW_DONE" /tmp/wm-lf016-integration.txt || fail "integration done"

# 4. Real E2E: redact -> route -> complete -> usage, gameplay preserved.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example e2e_provider_flow > /tmp/wm-lf016-e2e.txt 2>&1 \
  || { cat /tmp/wm-lf016-e2e.txt; fail "e2e_provider_flow"; }
grep -q "E2E gameplay-after-failure: ok" /tmp/wm-lf016-e2e.txt || fail "gameplay preserved"
grep -q "E2E_PROVIDER_FLOW_DONE" /tmp/wm-lf016-e2e.txt || fail "e2e done"

# 5. Fallback behavior under controlled failure (real mechanisms).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example failure_matrix > /tmp/wm-lf016-failure.txt 2>&1 \
  || { cat /tmp/wm-lf016-failure.txt; fail "failure_matrix"; }
grep -q "M4 unavailable: ok" /tmp/wm-lf016-failure.txt || fail "unavailable fallback"
grep -q "M4 timeout: ok" /tmp/wm-lf016-failure.txt || fail "timeout fallback"
grep -q "M4 cancel-mid-stream: ok" /tmp/wm-lf016-failure.txt || fail "cancel fallback"

# 6. Real gates: feature coverage and spec trace.
sh scripts/feature-coverage-check.sh >/dev/null || fail "feature coverage"
sh scripts/spec-trace-check.sh >/dev/null || fail "spec trace"

echo "LF-016: ok (provider certified, routing, fallback, gameplay preserved)"
