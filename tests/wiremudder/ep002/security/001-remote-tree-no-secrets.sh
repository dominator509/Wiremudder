#!/usr/bin/env sh
# Security test: no secrets may be committed to origin; the remote tree
# must not contain .env, keys, or credential files.
set -eu
python3 - <<'PY' || { echo "FAIL: remote tree secret scan" >&2; exit 1; }
import subprocess
out = subprocess.run(['git','ls-tree','-r','--name-only','origin/wire/development'], text=True, stdout=subprocess.PIPE).stdout
files = out.splitlines()
bad_prefixes = ('secrets/', '*.pem', '*.key', 'id_rsa', 'id_ed25519')
for f in files:
    assert not f.startswith('secrets/'), f'secrets pushed: {f}'
    if f.endswith(('.pem', '.key')):
        assert 'test' in f or 'fixture' in f, f'possible key pushed: {f}'
# .env.example is the intentional template; a real .env must never be pushed.
assert '.env.example' in files, '.env.example missing (expected template)'
for f in files:
    assert not (f.startswith('.env') and f != '.env.example'), f'.env pushed: {f}'
print(f'security remote-tree-no-secrets: ok files={len(files)}')
PY
echo "security remote-tree-no-secrets: ok"
