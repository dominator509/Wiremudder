#!/usr/bin/env sh
# Security test: replay fixtures committed to the tree contain no
# secrets, player names, or private transcripts (SPEC-019-R05).
set -eu
python3 - <<'PY' || { echo "FAIL: fixture secret scan" >&2; exit 1; }
import json, re
from pathlib import Path
secrets = [
    re.compile(r'\b(api[_-]?key|secret|password|token|private[_-]?key)\s*[=:]\s*\S+', re.I),
    re.compile(r'\bAKIA[0-9A-Z]{16}\b'),
    re.compile(r'-----BEGIN (?:RSA|OPENSSH|EC|PRIVATE) KEY-----'),
]
names = ('Dominic', 'Dominator', 'WireMudderTestPlayer')
count = 0
for p in Path('compatibility').rglob('*'):
    if not p.is_file() or p.suffix not in ('.json', '.py', '.md', '.sh'):
        continue
    count += 1
    text = p.read_text(encoding='utf-8', errors='replace')
    for pat in secrets:
        assert not pat.search(text), f'secret pattern in {p}: {pat.pattern}'
    for name in names:
        # The sanitizer's DEFAULT_PLAYER_NAMES constant legitimately
        # lists names to strip; only actual fixture content must be clean.
        if 'DEFAULT_PLAYER_NAMES' in text and name in text and p.name == 'sanitize.py':
            continue
        assert name not in text, f'player name in {p}'
print(f'security fixture-scan: ok files={count}')
PY
echo "security fixture-scan: ok"
