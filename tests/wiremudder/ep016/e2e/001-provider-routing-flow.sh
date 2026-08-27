#!/usr/bin/env sh
# EP-016 M3 E2E: full provider flow (redact -> route -> complete -> usage ->
# evaluation) with manual gameplay preserved across provider failure.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-ai-router/Cargo.toml \
  --example e2e_provider_flow > /tmp/wm-ep016-e2e.txt 2>&1 \
  || { cat /tmp/wm-ep016-e2e.txt; fail "e2e_provider_flow"; }

for step in redact gameplay route fail-fast gameplay-after-failure; do
  grep -q "E2E $step: ok" /tmp/wm-ep016-e2e.txt || fail "e2e step $step not proven"
done
grep -q "E2E_PROVIDER_FLOW_DONE" /tmp/wm-ep016-e2e.txt || fail "missing done sentinel"

echo "e2e EP-016 M3 provider-routing-flow: ok"
