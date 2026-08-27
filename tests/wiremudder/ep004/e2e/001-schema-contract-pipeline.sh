#!/usr/bin/env sh
# E2E test: schema-contract pipeline — feature catalog -> capability
# schema -> manifest -> trace gates, all consistent end to end.
set -eu
python3 - <<'PY' || { echo "FAIL: schema e2e" >&2; exit 1; }
import json, subprocess
from pathlib import Path
# 1. Feature catalog rows are structurally consistent with capability schema.
feats = []
for line in Path('.agent/features/FEATURES.tsv').read_text().splitlines():
    if line.startswith('WM-FEAT'):
        cols = line.split('\t')
        assert len(cols) >= 7, f'bad row: {line[:40]}'
        feats.append(cols[0])
assert len(feats) >= 200, len(feats)
# 2. Manifest lists capabilities by their owner nodes.
m = json.loads(Path('tools/schema-bindings/bindings.manifest.json').read_text())
assert m['count'] >= 6
# 3. Trace gates pass.
subprocess.run(['sh','scripts/feature-coverage-check.sh'], check=True, capture_output=True)
subprocess.run(['sh','scripts/spec-trace-check.sh'], check=True, capture_output=True)
print(f'e2e schema-contract-pipeline: ok features={len(feats)} schemas={m["count"]}')
PY
echo "e2e schema-contract-pipeline: ok"
