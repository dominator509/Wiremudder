#!/usr/bin/env sh
# WM-FEAT-0128: sanitized fixture generator — strips secrets, player
# names, private messages, routing credentials, full prompts, and voice
# transcripts unless approved (SPEC-019-R05).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0128: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-replay/src/lib.rs
[ -f "$LIB" ] || fail "wire-replay crate missing"
grep -q "FixtureGenerator" "$LIB" || fail "fixture generator missing"
grep -q "with_player_names" "$LIB" || fail "player name stripping missing"
grep -q "STRIPPED_FIXTURE_KINDS" "$LIB" || fail "stripped kinds missing"
grep -q "MAX_FIXTURE_EVENTS" "$LIB" || fail "fixture bound missing"
grep -q "approved_kinds" "$LIB" || fail "approval-scoped inclusion missing"
echo "feature WM-FEAT-0128 sanitized-fixture-generator: ok"
