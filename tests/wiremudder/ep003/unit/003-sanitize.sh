#!/usr/bin/env sh
# Unit test: sanitization strips secrets and player names deterministically.
set -eu
python3 - <<'PY' || { echo "FAIL: sanitize" >&2; exit 1; }
import sys
sys.path.insert(0, 'compatibility/framework')
from sanitize import sanitize_line, sanitize_replay
line = 'Dominic says: token=abc123 and password=hunter2 and AKIAIOSFODNN7EXAMPLE'
out = sanitize_line(line)
assert 'Dominic' not in out and '[PLAYER]' in out, out
assert 'abc123' not in out and 'hunter2' not in out, out
assert 'AKIAIOSFODNN7EXAMPLE' not in out, out
doc = {
    'schema_version': 1,
    'events': [
        {'seq': 1, 't': 0, 'kind': 'line', 'direction': 'in', 'line': 'WireMudderTestPlayer tells you hi'},
        {'seq': 2, 't': 1, 'kind': 'command', 'direction': 'out', 'command': 'password=sekrit'},
    ],
}
clean = sanitize_replay(doc)
assert 'WireMudderTestPlayer' not in clean['events'][0]['line'], clean
assert 'sekrit' not in clean['events'][1]['command'], clean
print('unit sanitize: ok')
PY
echo "unit sanitize: ok"
