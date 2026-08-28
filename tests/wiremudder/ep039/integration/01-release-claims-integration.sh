#!/usr/bin/env sh
# EP-039 M3 integration: the release-claims gate integrates with the real
# capability matrix and feature table — full profile claims must be exactly
# the set of certified features, no more.
set -eu
cd "$(dirname "$0")/../../../.."

out=$(WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh 2>&1)
echo "$out" | grep -q 'release claims: ok' || { echo "FAIL: $out" >&2; exit 1; }

python3 - <<'PY'
import csv, pathlib
matrix = list(csv.DictReader(open('docs/wiremudder/release-candidate/CAPABILITY_MATRIX.tsv', encoding='utf-8'), delimiter='\t'))
feats = list(csv.DictReader(open('.agent/features/FEATURES.tsv', encoding='utf-8'), delimiter='\t'))
matrix_ids = {r['feature_id'] for r in matrix}
feature_ids = {r['id'] for r in feats}
# The matrix must cover every feature the feature table declares.
missing = feature_ids - matrix_ids
assert not missing, f"features missing from capability matrix: {sorted(missing)}"
# Every certified matrix row must point at a real evidence file or test dir.
for r in matrix:
    if r['state'] in {'live-fire-certified','certified','implemented'}:
        p = pathlib.Path(r['evidence'])
        assert p.exists(), f"missing evidence {r['evidence']} for {r['feature_id']}"
print(f'claims integration: ok (matrix {len(matrix_ids)}, features {len(feature_ids)})')
PY
