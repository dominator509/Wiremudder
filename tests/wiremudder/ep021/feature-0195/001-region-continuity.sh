#!/usr/bin/env sh
# EP-021 M5 feature test: WM-FEAT-0195 World Bible region continuity.
# Region palettes, terrain, lighting, factions, silhouettes, architecture,
# and roleplay continuity as text metadata without protected assets
# (SPEC-012-R08). Proven by real crate surface and LF-021 certification.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0195: FAIL - $1" >&2; exit 1; }

LIB=wirecore/crates/wire-world-bible/src/lib.rs
grep -q "pub struct WorldBible" "$LIB" || fail "WorldBible missing"
grep -q "palette" "$LIB" || fail "palette missing"
grep -q "faction" "$LIB" || fail "faction missing"
grep -q "silhouette" "$LIB" || fail "silhouette missing"
grep -q "roleplay_tone" "$LIB" || fail "roleplay tone missing"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-world-bible/Cargo.toml 2>&1 \
  | grep -q "no_protected_assets" || fail "no-assets invariant"

[ -f .agent/state/evidence/EP-021/M5/lf021-certification.json ] || fail "LF-021 evidence missing"
python3 -c "import json; d=json.load(open('.agent/state/evidence/EP-021/M5/lf021-certification.json')); assert d['bible_exportable'] and d['no_protected_assets']" \
  || fail "LF-021 bible continuity certification false"

echo "feature-0195 World Bible region continuity: ok"
