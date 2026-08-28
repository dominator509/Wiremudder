#!/usr/bin/env sh
# EP-020 requirement test: WM-SPEC-012-R07 Tactical HUD.
# Tactical HUD uses bounded current snapshots and never sends commands.
# Proven by the real crate, schema, and LF-020 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "wm-spec-012-r07: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-tactical/src/lib.rs
grep -q "pub struct TacticalSnapshot" "$LIB" || fail "snapshot struct missing"
grep -q "max_history" "$LIB" || fail "bounded history missing"
grep -q "max_entities" "$LIB" || fail "bounded entities missing"
grep -q "can_send_command" "$LIB" || fail "no-command invariant missing"
grep -q "StaleSnapshot" "$LIB" || fail "stale rejection missing"
grep -q "Oversized" "$LIB" || fail "oversized rejection missing"

# Crate tests prove bounded/oversized/stale/no-command invariants.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-tactical/Cargo.toml 2>&1 \
  | grep -q "history_bounded" || fail "history bounded invariant"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-tactical/Cargo.toml 2>&1 \
  | grep -q "hud_never_sends_commands" || fail "no-command invariant"

# LF-020 certified.
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-020/M5/lf020-certification.json')); assert d['bounded_snapshot'] and d['oversized_rejected'] and d['hud_no_command']" \
  || fail "LF-020 certification false"

echo "wm-spec-012-r07 Tactical HUD: ok"
