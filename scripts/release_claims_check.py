#!/usr/bin/env python3
from __future__ import annotations
import csv, os, sys
from pathlib import Path
root = Path.cwd(); matrix = root / 'docs/wiremudder/release-candidate/CAPABILITY_MATRIX.tsv'
features_file = root / '.agent/features/FEATURES.tsv'
if not matrix.is_file() or not features_file.is_file():
    print('release claims: FAIL - missing capability or feature matrix', file=sys.stderr); raise SystemExit(1)
with features_file.open(encoding='utf-8', newline='') as handle:
    feature_rows = list(csv.DictReader(handle, delimiter='\t'))
with matrix.open(encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
feature_ids = {row['id'] for row in feature_rows}
claim_ids = [row.get('feature_id','') for row in rows]
if set(claim_ids) != feature_ids or len(claim_ids) != len(set(claim_ids)):
    print(f'release claims: FAIL - feature set mismatch missing={sorted(feature_ids-set(claim_ids))} extra={sorted(set(claim_ids)-feature_ids)}', file=sys.stderr); raise SystemExit(1)
valid = {'declared','implemented','tested','live-fire-certified','disabled','blocked'}
for row in rows:
    state = row.get('state',''); evidence = row.get('evidence','').strip(); fid = row.get('feature_id','')
    if state not in valid:
        print(f'release claims: FAIL - invalid state {fid}/{state}', file=sys.stderr); raise SystemExit(1)
    if state in {'implemented','tested','live-fire-certified'}:
        if not evidence or not (root / evidence).exists():
            print(f'release claims: FAIL - evidence missing for {fid}', file=sys.stderr); raise SystemExit(1)
    if state == 'live-fire-certified' and not evidence.startswith('.agent/state/'):
        print(f'release claims: FAIL - certification lacks immutable evidence path {fid}', file=sys.stderr); raise SystemExit(1)
profile = os.environ.get('WIREMUDDER_RELEASE_PROFILE','core').strip()
profiles = {'core': {'core','release'}, 'ai': {'core','ai','release'}, 'immersion': {'core','ai','immersion','release'}, 'developer': {'core','developer','release'}, 'full': {'core','ai','immersion','developer','full','release'}}
if profile not in profiles:
    print(f'release claims: FAIL - invalid release profile {profile}', file=sys.stderr); raise SystemExit(1)
feature_profile = {row['id']: row['profile'] for row in feature_rows}
for row in rows:
    fid = row['feature_id']; state = row['state']; declared_profile = feature_profile[fid]
    if declared_profile not in profiles[profile] and state not in {'disabled','blocked'}:
        print(f'release claims: FAIL - out-of-profile feature is claimed: {fid}', file=sys.stderr); raise SystemExit(1)
print(f'release claims: ok features={len(rows)} profile={profile}')
