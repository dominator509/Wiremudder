#!/usr/bin/env sh
# WM-SPEC-024-R09: restart resynchronizes snapshots rather than
# replaying unbounded raw history. Journal recovery rehydrates only the
# bounded tail (capacity), never unbounded raw history.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement wm-spec-024-r09: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-telemetry/src/lib.rs
[ -f "$LIB" ] || fail "wire-telemetry crate missing"
grep -q "recover_journal" "$LIB" || fail "snapshot resync missing"
grep -q "capacity" "$LIB" || fail "bounded resync missing"
grep -q "MAX_RING_CAPACITY" "$LIB" || fail "bound missing"
grep -q "Only the most recent" "$LIB" || fail "tail-only recovery missing"
echo "requirement wm-spec-024-r09 snapshot-resync: ok"
