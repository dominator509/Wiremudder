#!/usr/bin/env sh
# EP-025 M2 unit test: renderer schemas must exist, be valid JSON, and
# declare the accepted contracts (mode catalog, emit catalog, asset
# provenance, style capsules).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for s in snapshot-v1 emit-v1 asset-pack-v1 style-capsule-v1; do
  f="schemas/wiremudder/renderer/$s.json"
  [ -f "$f" ] || fail "missing schema $f"
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid JSON in $f"
done

grep -q '"text-only"' schemas/wiremudder/renderer/snapshot-v1.json || fail "snapshot lacks text-only mode"
grep -q '"room-event"' schemas/wiremudder/renderer/emit-v1.json || fail "emit lacks room-event kind"
grep -q '"pvp-visible"' schemas/wiremudder/renderer/emit-v1.json || fail "emit lacks pvp-visible kind"
grep -q '"confidence"' schemas/wiremudder/renderer/emit-v1.json || fail "emit lacks confidence"
grep -q '"sha256"' schemas/wiremudder/renderer/asset-pack-v1.json || fail "asset pack lacks hash"
grep -q '"signature"' schemas/wiremudder/renderer/asset-pack-v1.json || fail "asset pack lacks signature"
grep -q '"user_local"' schemas/wiremudder/renderer/asset-pack-v1.json || fail "asset pack lacks local source"
grep -q '"palette"' schemas/wiremudder/renderer/style-capsule-v1.json || fail "capsule lacks palette"

# Original assets manifest must be present and valid with provenance.
[ -f assets/wiremudder/renderer/manifest.json ] || fail "missing renderer asset manifest"
python3 -c "import json,sys; json.load(open('assets/wiremudder/renderer/manifest.json'))" || fail "invalid asset manifest"
grep -q "original:wiremudder:procedural" assets/wiremudder/renderer/manifest.json || fail "assets lack original provenance"
grep -q "CC0" assets/wiremudder/renderer/manifest.json || fail "assets lack license"
grep -q "copy Nintendo" assets/wiremudder/renderer/README.md || fail "README lacks protected-asset statement"

echo "unit renderer-schemas: ok"
