#!/usr/bin/env sh
# Integration test: UPSTREAM.lock.yaml fields must match the actual
# repository state (commit present, upstream remote, stable release tag).
set -eu
. ./.env
commit=$WIREMUDDER_UPSTREAM_COMMIT
git cat-file -e "$commit^{commit}" || { echo "FAIL: pinned commit $commit missing" >&2; exit 1; }
[ "$(git config --get remote.upstream.url)" = "https://github.com/Mudlet/Mudlet.git" ] || { echo "FAIL: upstream remote mismatch" >&2; exit 1; }
python3 - <<'PY' || { echo "FAIL: lock/repo mismatch" >&2; exit 1; }
import re, subprocess
from pathlib import Path
text = Path('UPSTREAM.lock.yaml').read_text(encoding='utf-8')
m = re.search(r'development_commit:\s*"([0-9a-f]{40})"', text)
assert m, 'no development_commit'
lock_commit = m.group(1)
head = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
assert lock_commit == head or subprocess.run(['git','merge-base','--is-ancestor',lock_commit,'HEAD']).returncode == 0, f'lock commit {lock_commit} is not HEAD or an ancestor of HEAD {head}'
assert 'tag: "Mudlet-4.22.0"' in text, 'stable release tag missing'
print('integration lock-state: ok')
PY
echo "integration lock-state: ok"
