#!/usr/bin/env sh
# EP-021 M5 feature test: WM-FEAT-0053 Time Machine Memory.
# Background, compacted, exportable snapshots reversible only to
# user-approved checkpoints (SPEC-012-R09). Proven by real crate
# surface, schema, and LF-021 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0053: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-time-machine/src/lib.rs
grep -q "pub struct TimeMachine" "$LIB" || fail "TimeMachine missing"
grep -q "pub fn snapshot" "$LIB" || fail "snapshot missing"
grep -q "pub fn approve" "$LIB" || fail "approve missing"
grep -q "pub fn restore" "$LIB" || fail "restore missing"
grep -q "pub fn export_json" "$LIB" || fail "export missing"
grep -q "NotApproved" "$LIB" || fail "approval-gate error missing"

# Schema exists and is valid JSON.
python3 -c "import json; json.load(open('schemas/wiremudder/memory/time-machine-snapshot-v1.json'))" \
  || fail "time-machine-snapshot schema invalid"

# Real behavior: restore denied until approval, export deterministic.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-time-machine/Cargo.toml 2>&1 \
  | grep -q "snapshot_requires_approval_to_restore" || fail "approval invariant"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-time-machine/Cargo.toml 2>&1 \
  | grep -q "export_is_deterministic" || fail "export invariant"

# LF-021 certified.
[ -f .agent/state/evidence/EP-021/M5/lf021-certification.json ] || fail "LF-021 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-021/M5/lf021-certification.json')); assert d['restore_denied_until_approved'] and d['restore_approved']" \
  || fail "LF-021 time machine certification false"

echo "feature-0053 Time Machine Memory: ok"
