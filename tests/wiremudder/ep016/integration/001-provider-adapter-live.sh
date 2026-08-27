#!/usr/bin/env sh
# EP-016 M3 integration: real provider boundary through the adapter crate.
# Requires the certified local path (Ollama on 127.0.0.1:11434) for the
# live section; all non-live states run regardless.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

# Controlled dependency: the local provider must be reachable.
curl -sf --max-time 5 http://127.0.0.1:11434/api/tags >/dev/null 2>&1 \
  || fail "local provider (Ollama 127.0.0.1:11434) not reachable"

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example integration_flow > /tmp/wm-ep016-integration.txt 2>&1 \
  || { cat /tmp/wm-ep016-integration.txt; fail "integration_flow"; }

for state in ready privacy disabled disabled-route denied degraded unavailable canceled error evaluation; do
  grep -q "STATE $state: ok" /tmp/wm-ep016-integration.txt || fail "state $state not proven"
done
grep -q "INTEGRATION_FLOW_DONE" /tmp/wm-ep016-integration.txt || fail "missing done sentinel"
grep -q "LIVE complete: ok" /tmp/wm-ep016-integration.txt || fail "live provider completion missing"
grep -q "LIVE stream: ok" /tmp/wm-ep016-integration.txt || fail "live provider streaming missing"
grep -q "LIVE usage: ok" /tmp/wm-ep016-integration.txt || fail "live usage missing"

echo "integration EP-016 M3 provider-adapter-live: ok"
