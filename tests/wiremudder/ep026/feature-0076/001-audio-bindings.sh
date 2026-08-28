#!/usr/bin/env sh
# WM-FEAT-0076: room/area/combat/boss/weather/death/victory audio
# bindings (plus ambience and user-authored per WM-SPEC-016-R08).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0076: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-soundscape/src/lib.rs
[ -f "$LIB" ] || fail "wire-soundscape crate missing"
for kind in Room Area Combat Boss Weather Death Victory Ambience UserAuthored; do
  grep -q "$kind" "$LIB" || fail "binding class $kind missing"
done
grep -q "fn all() -> \[SoundscapeKind; 9\]" "$LIB" || fail "nine-class catalog missing"
grep -q "register_binding" "$LIB" || fail "binding registration missing"
grep -q "user_author" "$LIB" || fail "user-authored binding support missing"
echo "feature WM-FEAT-0076 audio-bindings: ok"
