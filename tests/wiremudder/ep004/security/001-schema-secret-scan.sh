#!/usr/bin/env sh
# Security test: canonical schemas and bindings contain no credential
# patterns and no secrets.
set -eu
python3 - <<'PY' || { echo "FAIL: schema secret scan" >&2; exit 1; }
import re
from pathlib import Path
patterns = [
    re.compile(r'\b(api[_-]?key|secret|password|token)\s*[=:]\s*\S+', re.I),
    re.compile(r'-----BEGIN (?:RSA|OPENSSH|EC|PRIVATE) KEY-----'),
    re.compile(r'\bAKIA[0-9A-Z]{16}\b'),
]
count = 0
for p in list(Path('schemas/wiremudder').rglob('*.json')) + [Path('tools/schema-bindings/bindings.manifest.json')]:
    count += 1
    text = p.read_text(encoding='utf-8')
    for pat in patterns:
        assert not pat.search(text), f'{p}: {pat.pattern}'
assert count >= 7, f'expected >=7 schema files, got {count}'
print(f'security schema-secret-scan: ok files={count}')
PY
echo "security schema-secret-scan: ok"
