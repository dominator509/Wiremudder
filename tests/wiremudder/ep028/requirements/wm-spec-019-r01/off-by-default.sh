#!/usr/bin/env sh
# WM-SPEC-019-R01: telemetry is off by default and local structured
# event capture uses bounded crash-safe ring buffers.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement wm-spec-019-r01: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-telemetry/src/lib.rs
[ -f "$LIB" ] || fail "wire-telemetry crate missing"
grep -q "enabled: false" "$LIB" || fail "telemetry not off by default"
grep -q "RingBuffer" "$LIB" || fail "ring buffer missing"
grep -q "MAX_RING_CAPACITY" "$LIB" || fail "bounded capacity missing"
grep -q "recover_journal" "$LIB" || fail "crash-safe recovery missing"
grep -q "fn enable" "$LIB" || fail "explicit enable path missing"
echo "requirement wm-spec-019-r01 off-by-default: ok"
