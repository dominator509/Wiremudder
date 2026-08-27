#!/usr/bin/env sh
# Security test: classification evidence and governance docs contain no
# credential-like strings.
set -eu
python3 - <<'PY' || { echo "FAIL: governance secret scan" >&2; exit 1; }
import re
from pathlib import Path
patterns = [
    re.compile(r'\b(api[_-]?key|secret|password|token|private[_-]?key)\s*[=:]\s*\S+', re.I),
    re.compile(r'-----BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY-----'),
    re.compile(r'\bAKIA[0-9A-Z]{16}\b'),
]
for p in [Path('docs/wiremudder/upstream'), Path('tests/wiremudder/ep002')]:
    for f in p.rglob('*'):
        if f.is_file() and f.suffix in ('.md', '.sh', '.py', '.tsv'):
            text = f.read_text(encoding='utf-8', errors='replace')
            for pat in patterns:
                assert not pat.search(text), f'possible secret in {f}: {pat.pattern}'
print('security governance-no-secrets: ok')
PY
echo "security governance-no-secrets: ok"
