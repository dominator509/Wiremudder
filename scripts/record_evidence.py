#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, os, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path
if len(sys.argv) < 6 or '--' not in sys.argv:
    print('usage: record_evidence.py NODE MILESTONE SENTINEL -- COMMAND ARGS', file=sys.stderr); raise SystemExit(2)
node, milestone, sentinel = sys.argv[1:4]
sep = sys.argv.index('--')
command = sys.argv[sep + 1:]
if not command:
    print('record evidence: missing command', file=sys.stderr); raise SystemExit(2)
proc = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
output = proc.stdout
print(output, end='')
dirpath = Path('.agent/state/evidence') / node / milestone
dirpath.mkdir(parents=True, exist_ok=True)
log = dirpath / 'output.log'
log.write_text(output, encoding='utf-8')
record = {
    'schema_version': 1,
    'node': node,
    'milestone': milestone,
    'observed_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'agent_id': os.environ.get('WIREMUDDER_AGENT_ID', 'unknown-agent'),
    'command': command,
    'exit_code': proc.returncode,
    'expected_sentinel': sentinel,
    'sentinel_observed': sentinel in output,
    'output_sha256': hashlib.sha256(output.encode('utf-8')).hexdigest(),
}
(dirpath / 'evidence.json').write_text(json.dumps(record, indent=2, sort_keys=True) + '\n', encoding='utf-8')
if proc.returncode != 0 or sentinel not in output:
    raise SystemExit(proc.returncode if proc.returncode != 0 else 1)
