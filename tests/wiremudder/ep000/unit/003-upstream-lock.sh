#!/usr/bin/env sh
# Unit test: UPSTREAM.lock.yaml must record the required provenance fields.
set -eu
[ -f UPSTREAM.lock.yaml ] || { echo "FAIL: UPSTREAM.lock.yaml missing" >&2; exit 1; }
python3 - <<'PY' || { echo "FAIL: UPSTREAM.lock.yaml invalid" >&2; exit 1; }
import re
from pathlib import Path
text = Path('UPSTREAM.lock.yaml').read_text(encoding='utf-8')
required = [
    'repository:', 'default_branch:', 'development_commit:', 'stable_release:',
    'tag:', 'published_at:', 'verified_at:', 'evidence:', 'path:', 'sha:',
]
for field in required:
    assert field in text, f'missing field {field}'
m = re.search(r'development_commit:\s*"([0-9a-f]{40})"', text)
assert m, 'development_commit is not a pinned 40-hex commit'
commit = m.group(1)
import subprocess
subprocess.run(['git', 'cat-file', '-e', commit + '^{commit}'], check=True)
print(f'unit upstream-lock: ok commit={commit}')
PY
echo "unit upstream-lock: ok"
