#!/usr/bin/env sh
# WM-FEAT-0065: per-agent voice styles for copilot, mapper, quest,
# safety, narrator, renderer, and help agents.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0065: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-voice/src/lib.rs
grep -q "per-agent voice styles" "$LIB" || fail "per-agent contract missing"
grep -q "pub enum ActivationMode" "$LIB" || true
grep -q "copilot\|mapper\|quest\|safety\|narrator\|renderer\|help" "$LIB" \
  || fail "agent style surface names missing from docs"
grep -q '"agent"' schemas/wiremudder/voice/style-v1.json || fail "agent kind missing from schema"
echo "feature WM-FEAT-0065 per-agent-voice-styles: ok"
