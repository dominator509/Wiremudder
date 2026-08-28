#!/usr/bin/env sh
# WM-FEAT-0071: graphical emits for NPCs, mobs, animals, players,
# PKers/PvPers, items, spells, combat, movement, doors, weather,
# ambience, and room events.
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0071: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
for kind in Npc Mob Animal Player PvpVisible Item Spell Combat Movement Door Weather Ambience RoomEvent; do
  grep -q "$kind" "$LIB" || fail "emit kind $kind missing"
done
grep -q "pub struct VisualEmit" "$LIB" || fail "VisualEmit missing"
grep -q "pub confidence" "$LIB" || fail "confidence missing"
echo "feature WM-FEAT-0071 graphical-emits: ok"
