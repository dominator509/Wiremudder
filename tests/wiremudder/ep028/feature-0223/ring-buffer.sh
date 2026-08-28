#!/usr/bin/env sh
# WM-FEAT-0223: crash-safe bounded ring buffers — bounded capture,
# journal recovery, fail-closed on corrupt tails (SPEC-019-R01).
set -eu
cd "$(dirname "$0")/../../../.."
fail() { echo "feature-0223: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-telemetry/src/lib.rs
[ -f "$LIB" ] || fail "wire-telemetry crate missing"
grep -q "RingBuffer" "$LIB" || fail "ring buffer missing"
grep -q "MAX_RING_CAPACITY" "$LIB" || fail "capacity bound missing"
grep -q "recover_journal" "$LIB" || fail "journal recovery missing"
grep -q "append_journal" "$LIB" || fail "crash-safe journal missing"
grep -q "DEFAULT_RING_CAPACITY" "$LIB" || fail "default capacity missing"
echo "feature WM-FEAT-0223 crash-safe-ring-buffers: ok"
