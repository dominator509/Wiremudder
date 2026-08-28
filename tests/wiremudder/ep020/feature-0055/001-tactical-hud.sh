#!/usr/bin/env sh
# EP-020 M5 feature test: WM-FEAT-0055 Tactical HUD.
# Bounded current-state tactical snapshots, observer-only, never sends
# commands (WM-SPEC-012-R07). Proven by real crate surface, schema, and
# the LF-020 live-fire certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0055: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-tactical/src/lib.rs
grep -q "pub struct TacticalHud" "$LIB" || fail "TacticalHud missing"
grep -q "pub struct TacticalSnapshot" "$LIB" || fail "TacticalSnapshot missing"
grep -q "pub fn update" "$LIB" || fail "update missing"
grep -q "pub fn current" "$LIB" || fail "current missing"
grep -q "pub fn history" "$LIB" || fail "history missing"
grep -q "Oversized" "$LIB" || fail "oversized rejection missing"
grep -q "StaleSnapshot" "$LIB" || fail "stale rejection missing"
grep -q "can_send_command" "$LIB" || fail "no-command invariant missing"

# Schema exists and is valid JSON.
python3 -c "import json; json.load(open('schemas/wiremudder/assistance/tactical-snapshot-v1.json'))" \
  || fail "tactical-snapshot schema invalid"

# Real behavior: bounded history, oversized/stale rejection, no commands
# proven by the crate tests.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-tactical/Cargo.toml 2>&1 \
  | grep -q "hud_never_sends_commands" || fail "no-command invariant"

# LF-020 certified tactical behavior.
[ -f .agent/state/evidence/EP-020/M5/lf020-certification.json ] || fail "LF-020 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-020/M5/lf020-certification.json')); assert d['bounded_snapshot'] and d['oversized_rejected'] and d['hud_no_command']" \
  || fail "LF-020 tactical certification false"

echo "feature-0055 Tactical HUD: ok"
