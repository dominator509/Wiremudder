#!/usr/bin/env sh
# EP-026 M2 unit test: audio schemas must exist, be valid JSON, and
# declare the accepted contracts (binding kinds, asset provenance,
# profile-scoped studio controls, bounded transitions).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for s in binding-v1 asset-pack-v1 soundscape-state-v1 studio-config-v1 transition-v1; do
  f="schemas/wiremudder/audio/$s.json"
  [ -f "$f" ] || fail "missing schema $f"
  python3 -c "import json,sys; json.load(open('$f'))" || fail "invalid JSON in $f"
done

grep -q '"room"' schemas/wiremudder/audio/binding-v1.json || fail "binding lacks room kind"
grep -q '"boss"' schemas/wiremudder/audio/binding-v1.json || fail "binding lacks boss kind"
grep -q '"weather"' schemas/wiremudder/audio/binding-v1.json || fail "binding lacks weather kind"
grep -q '"user-authored"' schemas/wiremudder/audio/binding-v1.json || fail "binding lacks user-authored kind"
grep -q '"volume"' schemas/wiremudder/audio/binding-v1.json || fail "binding lacks independent volume"
grep -q '"enabled"' schemas/wiremudder/audio/binding-v1.json || fail "binding lacks disable control"
grep -q '"sha256"' schemas/wiremudder/audio/asset-pack-v1.json || fail "asset pack lacks hash"
grep -q '"signature"' schemas/wiremudder/audio/asset-pack-v1.json || fail "asset pack lacks signature"
grep -q '"user_local"' schemas/wiremudder/audio/asset-pack-v1.json || fail "asset pack lacks local source"
grep -q '"profiles"' schemas/wiremudder/audio/studio-config-v1.json || fail "studio config lacks profile scope"
grep -q '"maximum": 5000' schemas/wiremudder/audio/transition-v1.json || fail "transition lacks bound"
grep -q '"coalesced"' schemas/wiremudder/audio/soundscape-state-v1.json || fail "state lacks coalesced metric"

# Original audio assets manifest must be present and valid with provenance.
[ -f assets/wiremudder/audio/manifest.json ] || fail "missing audio asset manifest"
python3 -c "import json,sys; json.load(open('assets/wiremudder/audio/manifest.json'))" || fail "invalid asset manifest"
grep -q "original:wiremudder:procedural" assets/wiremudder/audio/manifest.json || fail "assets lack original provenance"
grep -q "CC0" assets/wiremudder/audio/manifest.json || fail "assets lack license"
grep -q "copy Nintendo" assets/wiremudder/audio/README.md || fail "README lacks protected-asset statement"

echo "unit EP-026 audio-schemas: ok"
