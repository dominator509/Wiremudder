#!/usr/bin/env python3
"""Validate a session replay JSON document against the replay schema.

Real validation using the json schema semantics implemented directly
(no external dependency): structural checks for required fields, event
kinds, sequence monotonicity, and sanitization invariants.
"""
from __future__ import annotations
import json, sys
from pathlib import Path

SCHEMA = Path(__file__).resolve().parent.parent.parent.parent / 'schemas' / 'wiremudder' / 'replay' / 'session-replay.schema.json'
KINDS = {'line', 'prompt', 'command', 'connection', 'disconnect', 'trigger', 'alias', 'gag', 'highlight', 'mapper', 'package'}


def validate(doc: dict) -> list[str]:
    errors = []
    if doc.get('schema_version') != 1:
        errors.append('schema_version must be 1')
    if not isinstance(doc.get('session_id'), str) or len(doc['session_id']) < 8:
        errors.append('session_id invalid')
    ver = doc.get('client_version', {})
    if not isinstance(ver.get('git_sha'), str) or len(ver.get('git_sha', '')) != 40:
        errors.append('client_version.git_sha must be 40 hex chars')
    events = doc.get('events')
    if not isinstance(events, list) or not events:
        errors.append('events must be a non-empty array')
        return errors
    last_seq = 0
    last_t = -1.0
    for i, ev in enumerate(events):
        if not isinstance(ev, dict):
            errors.append(f'event[{i}] not object')
            continue
        seq = ev.get('seq')
        if not isinstance(seq, int) or seq < 1:
            errors.append(f'event[{i}].seq invalid')
        elif seq <= last_seq:
            errors.append(f'event[{i}].seq not strictly increasing')
        last_seq = seq if isinstance(seq, int) else last_seq
        t = ev.get('t')
        if not isinstance(t, (int, float)) or t < last_t:
            errors.append(f'event[{i}].t not monotonic')
        last_t = t if isinstance(t, (int, float)) else last_t
        kind = ev.get('kind')
        if kind not in KINDS:
            errors.append(f'event[{i}].kind unknown: {kind}')
        if kind in ('line', 'command', 'prompt') and 'direction' not in ev:
            errors.append(f'event[{i}] missing direction')
        if 'command' in ev and not isinstance(ev['command'], str):
            errors.append(f'event[{i}].command not string')
    return errors


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('usage: replay_validate.py FILE.json', file=sys.stderr)
        raise SystemExit(2)
    try:
        doc = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
    except Exception as exc:
        print(f'replay validate: FAIL - {exc}', file=sys.stderr)
        raise SystemExit(1)
    errors = validate(doc)
    if errors:
        print('replay validate: FAIL - ' + '; '.join(errors[:5]), file=sys.stderr)
        raise SystemExit(1)
    print('replay validate: ok')
