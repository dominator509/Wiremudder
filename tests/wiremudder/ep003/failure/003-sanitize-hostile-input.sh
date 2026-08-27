#!/usr/bin/env sh
# Failure test: sanitization must never emit secrets even when input is
# hostile (denied policy proof).
set -eu
python3 - <<'PY' || { echo "FAIL: hostile sanitize" >&2; exit 1; }
import sys
sys.path.insert(0, 'compatibility/framework')
from sanitize import sanitize_line, sanitize_replay
hostile = 'api_key=sk-ABCDEFGHIJKLMNOPQRST password=12345 token=tok_xyz AKIAIOSFODNN7EXAMPLE Bearer zzzz'
out = sanitize_line(hostile)
for bad in ('sk-ABCDEFGHIJKLMNOPQRST', '12345', 'tok_xyz', 'AKIAIOSFODNN7EXAMPLE', 'zzzz'):
    assert bad not in out, f'leaked {bad}: {out}'
doc = {'schema_version': 1, 'events': [{'seq':1,'t':0,'kind':'line','direction':'in','line':hostile}]}
clean = sanitize_replay(doc)
assert 'sk-ABCDEFGHIJKLMNOPQRST' not in clean['events'][0]['line']
print('failure sanitize-hostile-input: ok')
PY
echo "failure sanitize-hostile-input: ok"
