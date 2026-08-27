#!/usr/bin/env sh
# Unit test: replay schema validator accepts valid docs and rejects
# malformed ones (sequence, kind, git_sha invariants).
set -eu
python3 - <<'PY' || { echo "FAIL: replay validator" >&2; exit 1; }
import json, sys
sys.path.insert(0, 'compatibility/replay')
from replay_validate import validate
valid = {
    'schema_version': 1,
    'session_id': 'abc12345',
    'client_version': {'app': 'WireMudder', 'git_sha': 'a'*40},
    'events': [
        {'seq': 1, 't': 0.0, 'kind': 'line', 'direction': 'in', 'line': 'hello'},
        {'seq': 2, 't': 5.0, 'kind': 'command', 'direction': 'out', 'command': 'look'},
    ],
}
assert validate(valid) == [], validate(valid)
bad = dict(valid)
bad['events'][1]['seq'] = 1  # duplicate seq
assert validate(bad), 'duplicate seq accepted'
bad2 = dict(valid)
bad2['client_version']['git_sha'] = 'short'
assert validate(bad2), 'bad git_sha accepted'
bad3 = dict(valid)
bad3['events'][0]['kind'] = 'nonsense'
assert validate(bad3), 'unknown kind accepted'
print('unit replay-validator: ok')
PY
echo "unit replay-validator: ok"
