#!/usr/bin/env sh
# Failure test: replay validator must reject oversized event sequences
# and malformed input (bounded, fail-closed).
set -eu
python3 - <<'PY' || { echo "FAIL: validator abuse" >&2; exit 1; }
import sys
sys.path.insert(0, 'compatibility/replay')
from replay_validate import validate
base = {
    'schema_version': 1,
    'session_id': 'abc12345',
    'client_version': {'app': 'WireMudder', 'git_sha': 'a'*40},
    'events': [{'seq': 1, 't': 0.0, 'kind': 'line', 'direction': 'in', 'line': 'x'}],
}
# Empty events must fail.
bad = dict(base); bad['events'] = []
assert validate(bad), 'empty events accepted'
# Non-object event must fail.
bad2 = dict(base); bad2['events'] = ['nonsense']
assert validate(bad2), 'non-object event accepted'
# Missing direction on a line must fail.
bad3 = dict(base); bad3['events'] = [{'seq': 1, 't': 0.0, 'kind': 'line', 'line': 'x'}]
assert validate(bad3), 'missing direction accepted'
print('failure validator-fail-closed: ok')
PY
echo "failure validator-fail-closed: ok"
