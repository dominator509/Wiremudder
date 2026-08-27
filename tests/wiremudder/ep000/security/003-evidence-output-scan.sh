#!/usr/bin/env sh
# Security test: evidence outputs must not contain secret-looking material
# (bearer tokens, private keys, API keys) and must match recorded hashes.
set -eu
python3 - <<'PY' || { echo "FAIL: evidence output security scan" >&2; exit 1; }
import hashlib, json, re
from pathlib import Path
rows = []
for raw in Path('.agent/state/source-evidence.jsonl').read_text(encoding='utf-8').splitlines():
    if raw.strip():
        rows.append(json.loads(raw))
assert rows
secret_patterns = [
    re.compile(r'\b(bearer|authorization):\s*\S+', re.I),
    re.compile(r'\b(api[_-]?key|secret|token|password)\s*[=:]\s*\S+', re.I),
    re.compile(r'-----BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY-----'),
]
for r in rows:
    outp = Path(r['output_path'])
    assert outp.is_file(), f'missing {r["output_path"]}'
    data = outp.read_text(encoding='utf-8', errors='replace')
    assert hashlib.sha256(data.encode('utf-8')).hexdigest() == r['output_sha256'], f'hash drift {r["evidence_id"]}'
    for pat in secret_patterns:
        assert not pat.search(data), f'possible secret in {r["evidence_id"]}: {pat.pattern}'
print(f'security evidence-output-scan: ok records={len(rows)}')
PY
echo "security evidence-output-scan: ok"
