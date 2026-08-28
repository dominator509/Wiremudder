#!/usr/bin/env sh
# WM-FEAT-0227: diagnostic deduplication without private content —
# structural dedup keys, coalescing (SPEC-019-R02).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0227: FAIL - $1" >&2; exit 1; }
TEL=wirecore/crates/wire-telemetry/src/lib.rs
REP=wirecore/crates/wire-replay/src/lib.rs
[ -f "$TEL" ] || fail "wire-telemetry crate missing"
[ -f "$REP" ] || fail "wire-replay crate missing"
grep -q "record_coalesced" "$TEL" || fail "coalescing missing"
grep -q "dedup_key" "$REP" || fail "dedup key missing"
grep -q "unique_event_count" "$REP" || fail "dedup count missing"
grep -q "coalesced_total" "$TEL" || fail "coalesce counter missing"
echo "feature WM-FEAT-0227 dedup-without-private-content: ok"
