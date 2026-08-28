#!/usr/bin/env sh
# LF-021 live-fire: world-memory-correction.
# Real controlled outcome for World Brain, World Bible, and Time Machine:
# provenance and confidence on facts, user correction supersedes without
# erasing history, hot/durable separation, exportable World Bible
# continuity without protected assets, safe restore only from
# user-approved checkpoints, private data scoped, observer-only surfaces.
set -eu
cd "$(dirname "$0")/../.."

fail() { echo "LF-021: FAIL - $1" >&2; exit 1; }

EVIDENCE=.agent/state/evidence/EP-021/M5/lf021-certification.json

# 1. Run the live world-memory fire (real crates, real schemas).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-brain/Cargo.toml \
  --example live_world_memory 2>&1 | tee /tmp/lf021_live.log
grep -q "LF-021 live: ok" /tmp/lf021_live.log || fail "live world-memory run"

# 2. Certification evidence is written with real measured values.
[ -f "$EVIDENCE" ] || fail "missing certification evidence $EVIDENCE"
python3 - "$EVIDENCE" <<'PY' || fail "invalid certification evidence"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["provenance_recorded"] is True
assert d["correction_supersedes"] is True
assert d["history_preserved"] is True
assert d["hot_durable_separate"] is True
assert d["bible_exportable"] is True
assert d["no_protected_assets"] is True
assert d["restore_denied_until_approved"] is True
assert d["restore_approved"] is True
assert d["private_scoped"] is True
assert d["brain_observer"] is True
assert d["bible_observer"] is True
assert d["time_machine_observer"] is True
PY

echo "LF-021: ok"
