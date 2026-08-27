#!/usr/bin/env python3
from __future__ import annotations
import subprocess, sys
from pathlib import Path
root = Path.cwd()
# EP-000 through EP-038 must be DONE before EP-039 closes.
for i in range(39):
    node = f'EP-{i:03d}'
    status = subprocess.check_output(['sh','scripts/ledger.sh','status',node], text=True).strip()
    if status != 'DONE':
        print(f'production readiness: FAIL - {node} is {status}', file=sys.stderr); raise SystemExit(1)
    tag = f'green/{node}'
    if subprocess.run(['git','rev-parse','-q','--verify',f'refs/tags/{tag}'], stdout=subprocess.DEVNULL).returncode != 0:
        print(f'production readiness: FAIL - missing tag {tag}', file=sys.stderr); raise SystemExit(1)
for rel in [
    'release/wiremudder/candidate/EVIDENCE_INDEX.json', 'sbom/wiremudder/SBOM.spdx.json', 'licenses/wiremudder/THIRD_PARTY_NOTICES.md',
    'docs/wiremudder/release-candidate/KNOWN_RISKS.md', 'docs/wiremudder/release-candidate/CAPABILITY_MATRIX.tsv',
]:
    if not (root / rel).is_file():
        print(f'production readiness: FAIL - missing {rel}', file=sys.stderr); raise SystemExit(1)
print('production readiness structural: ok')
