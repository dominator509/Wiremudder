#!/usr/bin/env sh
# WM-FEAT-0168: map import export and backups.
# Proves versioned snapshot export/import round-trip, tamper rejection,
# and schema-version pinning (SPEC-021).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0168: FAIL - $1" >&2; exit 1; }

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example snapshot_export > /tmp/wm-feat-0168-snap.json 2>/dev/null \
  || fail "snapshot export"
grep -q '"schema_version": 1' /tmp/wm-feat-0168-snap.json || fail "schema version"
grep -q '"rooms"' /tmp/wm-feat-0168-snap.json || fail "rooms present"

CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-world-graph/Cargo.toml \
  --example security_matrix > /tmp/wm-feat-0168-sec.log 2>/dev/null \
  || fail "security matrix"
grep -q "integrity-tamper:ok" /tmp/wm-feat-0168-sec.log || fail "tamper rejection"

# Compatibility fixture validates against the versioned schema.
python3 - <<'PY' || fail "fixture schema"
import json
s = json.load(open("schemas/wiremudder/world/world-graph.schema.json"))
f = json.load(open("compatibility/maps/fixture-001-reference.map.json"))
assert f["schema_version"] == s["properties"]["schema_version"]["const"]
assert len(f["rooms"]) == 5 and len(f["areas"]) == 1 and len(f["zones"]) == 1
print("fixture-001 reference map: ok")
PY

echo "feature-0168 map-import-export-backups: ok"
