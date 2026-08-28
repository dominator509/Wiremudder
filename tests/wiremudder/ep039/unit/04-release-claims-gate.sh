#!/usr/bin/env sh
# EP-039 M2 unit test: the release claims gate passes under the full profile
# and the capability matrix certifies only evidence-backed states.
set -eu
cd "$(dirname "$0")/../../../.."

out=$(WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh 2>&1) \
  || { echo "FAIL: release claims gate: $out" >&2; exit 1; }
echo "$out" | grep -q 'release claims: ok' \
  || { echo "FAIL: claims sentinel missing: $out" >&2; exit 1; }

matrix=docs/wiremudder/release-candidate/CAPABILITY_MATRIX.tsv
[ -f "$matrix" ] || { echo "FAIL: capability matrix missing" >&2; exit 1; }
python3 - "$matrix" <<'PY'
import csv, pathlib, sys
states = {'live-fire-certified', 'certified', 'disabled', 'blocked', 'implemented', 'tested'}
rows = list(csv.DictReader(open(sys.argv[1], encoding='utf-8'), delimiter='\t'))
assert rows, 'empty capability matrix'
for r in rows:
    assert r.get('feature_id','').startswith('WM-FEAT-'), f"bad feature id {r}"
    assert r.get('state') in states, f"bad state {r.get('state')} for {r.get('feature_id')}"
    if r.get('state') not in {'disabled','blocked'}:
        ev = r.get('evidence','')
        assert ev, f"missing evidence for {r.get('feature_id')}"
        # Certified states point at evidence records; 'tested' points at the
        # test directory that proved the feature (e.g. EP-038 unit suite).
        if r.get('state') in {'live-fire-certified','certified','implemented'}:
            assert ev.startswith('.agent/state/evidence/'), f"non-evidence path {ev}"
        else:
            assert pathlib.Path(ev).is_dir(), f"missing test dir {ev}"
print(f'capability matrix: ok ({len(rows)} features)')
PY

echo 'release claims and capability matrix: ok'
