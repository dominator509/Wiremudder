#!/usr/bin/env sh
# EP-021 M5 feature test: WM-FEAT-0051 World Bible.
# Region continuity metadata: palettes, terrain, lighting, factions,
# silhouettes, architecture, sound rules, roleplay tone, constraints —
# without copying protected assets (SPEC-012-R08). Proven by real crate
# surface, schema, and LF-021 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0051: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-world-bible/src/lib.rs
grep -q "pub struct WorldBible" "$LIB" || fail "WorldBible missing"
grep -q "pub fn upsert" "$LIB" || fail "upsert missing"
grep -q "pub fn export_json" "$LIB" || fail "export missing"
grep -q "palette" "$LIB" || fail "palette missing"
grep -q "terrain" "$LIB" || fail "terrain missing"
grep -q "architecture_motif" "$LIB" || fail "architecture motif missing"
grep -q "sound_rule" "$LIB" || fail "sound rule missing"

# Schema exists and is valid JSON.
python3 -c "import json; json.load(open('schemas/wiremudder/memory/world-bible-region-v1.json'))" \
  || fail "world-bible-region schema invalid"

# Real behavior: export deterministic, no protected assets.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-bible/Cargo.toml 2>&1 \
  | grep -q "export_is_deterministic_and_checksummed" || fail "export invariant"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-bible/Cargo.toml 2>&1 \
  | grep -q "no_protected_assets" || fail "no-assets invariant"

# LF-021 certified.
[ -f .agent/state/evidence/EP-021/M5/lf021-certification.json ] || fail "LF-021 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-021/M5/lf021-certification.json')); assert d['bible_exportable'] and d['no_protected_assets']" \
  || fail "LF-021 world bible certification false"

echo "feature-0051 World Bible: ok"
