#!/usr/bin/env python3
from datetime import datetime, timezone
from pathlib import Path
import sys
node = sys.argv[1]; limit = int(sys.argv[2])
latest = None
for line in Path('.agent/state/LEDGER.md').read_text(encoding='utf-8').splitlines():
    p = line.split(' | ', 4)
    if len(p) == 5 and p[2] == node and p[3] in {'LEASE', 'LEASE_TAKEOVER', 'HEARTBEAT', 'MILESTONE_PASS', 'ATTEMPT_FAIL', 'SIG'}:
        latest = datetime.strptime(p[0], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)
if latest is None:
    print('lease age: no lease evidence', file=sys.stderr); raise SystemExit(1)
age = (datetime.now(timezone.utc) - latest).total_seconds()
if age < limit:
    print(f'lease age: active age={int(age)} limit={limit}', file=sys.stderr); raise SystemExit(1)
print('lease age: stale')
