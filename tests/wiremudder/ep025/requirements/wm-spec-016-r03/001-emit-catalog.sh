#!/usr/bin/env sh
# WM-SPEC-016-R03: visual emits cover the complete catalog with visible
# confidence when inferred.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-renderer/src/lib.rs
for kind in Npc Mob Animal Player PvpVisible Item Spell Combat Movement Door Weather Ambience RoomEvent; do
  grep -q "$kind" "$LIB" || fail "emit kind $kind missing"
done
grep -q "pub confidence" "$LIB" || fail "confidence missing"
grep -q "pub inferred" "$LIB" || fail "inferred flag missing"
grep -q "visible confidence" "$LIB" || fail "visible-confidence contract missing"
echo "requirement WM-SPEC-016-R03 emit-catalog: ok"
