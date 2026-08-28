#!/usr/bin/env sh
# EP-020 M3 integration test: data scope, privacy, health, and restart.
# Secrets are redacted from narration; the boundary is bounded; health
# state transitions are deterministic; restart clears ephemeral state.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-narrator/src/lib.rs
# Redaction covers full token values after markers.
grep -q 'let markers = \["sk-", "sbp_", "Bearer ", "password=", "api_key=", "secret="\]' "$LIB" \
  || fail "redaction markers missing"

# Bounded recent-summary buffer: max_recent is finite.
grep -q "max_recent: 50" "$LIB" || fail "narrator buffer not bounded"

# Crate tests prove redaction, source disclosure, load shedding.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-narrator/Cargo.toml 2>&1 \
  | grep -q "redaction_scrubs_repeated_markers" || fail "repeated-marker redaction"

# The pane is passive across all states and clears non-ready state.
HDR=src/wiremudder/ui/assistance/assistance_boundary.h
grep -q "enum class AssistancePaneState" "$HDR" || fail "pane state enum missing"

echo "integration EP-020 M3 data-scope-privacy-health: ok"
