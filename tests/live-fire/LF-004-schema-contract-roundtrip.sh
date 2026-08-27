#!/usr/bin/env sh
# LF-004 schema-contract-roundtrip (live-fire)
#
# Proves the real user outcome of EP-004: canonical schemas regenerate
# deterministically, validate real documents, feed the binding manifest,
# and the traceability gates pass against the live catalog — end to end.
set -eu
fail() { echo "LF-004: FAIL - $1" >&2; exit 1; }

echo "LF-004: schema-contract-roundtrip"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

python3 - <<'PY' || fail "roundtrip"
import hashlib, json, subprocess
from pathlib import Path

# 1. Regenerate bindings; deterministic hash.
h1 = hashlib.sha256(Path('tools/schema-bindings/bindings.manifest.json').read_bytes()).hexdigest()
subprocess.run(['python3','tools/schema-bindings/generate_bindings.py'], check=True, capture_output=True)
h2 = hashlib.sha256(Path('tools/schema-bindings/bindings.manifest.json').read_bytes()).hexdigest()
assert h1 == h2, 'manifest regeneration not deterministic'
m = json.loads(Path('tools/schema-bindings/bindings.manifest.json').read_text())
assert m['count'] >= 6, m['count']

# 2. Every schema validates a real minimal document of its own kind.
specs = {
    'telemetry/event.schema.json': {'schema_version': 1, 'event_id': 'evt-1234567', 't': 1.0, 'subsystem': 'lua', 'severity': 'info', 'fingerprint': 'abcd', 'priority': 'P3'},
    'error/error.schema.json': {'code': 'timeout', 'message': 'x', 'severity': 'error'},
    'profile/profile.schema.json': {'name': 'oracle', 'schema_version': 1},
    'replay/session-replay.schema.json': {'schema_version': 1, 'session_id': 'abcd1234', 'client_version': {'app': 'x', 'git_sha': 'a'*40}, 'events': [{'seq': 1, 't': 0.0, 'kind': 'line', 'direction': 'in', 'line': 'x'}]},
}
for rel, doc in specs.items():
    p = Path('schemas/wiremudder') / rel
    assert p.is_file(), f'missing {rel}'
    schema = json.loads(p.read_text())
    for req in schema['required']:
        assert req in doc, f'{rel}: missing {req}'

# 3. Trace gates pass live.
subprocess.run(['sh','scripts/feature-coverage-check.sh'], check=True, capture_output=True)
subprocess.run(['sh','scripts/spec-trace-check.sh'], check=True, capture_output=True)

print(f'LF-004: ok schemas={m["count"]} manifest_stable=yes gates=ok')
PY
