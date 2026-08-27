#!/usr/bin/env sh
# Performance test: capture + sanitize + validate is bounded per scenario.
set -eu
python3 - <<'PY' || { echo "FAIL: oracle perf" >&2; exit 1; }
import subprocess, tempfile, time
from pathlib import Path
tmp = Path(tempfile.mkdtemp())
worst = 0.0
for sc in ('negotiation', 'text-stream', 'latency', 'disconnect', 'malformed'):
    out = tmp / f'{sc}.json'
    start = time.monotonic()
    subprocess.run(['python3','tools/protocol-museum/oracle_record.py', sc, str(out)], check=True, timeout=15)
    elapsed = time.monotonic() - start
    worst = max(worst, elapsed)
    assert elapsed < 10.0, f'{sc} took {elapsed:.2f}s'
print(f'performance oracle-capture: ok worst={worst*1000:.0f}ms')
PY
echo "performance oracle-capture: ok"
