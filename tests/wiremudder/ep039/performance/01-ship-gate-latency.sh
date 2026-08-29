#!/usr/bin/env sh
# EP-039 M4 performance: measure the ship-gate hot paths on this hardware and
# record raw evidence — evidence-index hashing and release-claims evaluation
# must complete within budget (p95 < 30s on this host).
set -eu
cd "$(dirname "$0")/../../../.."

out=.agent/state/evidence/EP-039/M4/perf-ship-gate.raw.tsv
mkdir -p "$(dirname "$out")"
echo "operation,wall_ms,host,date" > "$out"

measure() {
  label="$1"; shift
  start=$(date +%s%N)
  "$@" >/dev/null 2>&1
  end=$(date +%s%N)
  ms=$(( (end - start) / 1000000 ))
  echo "$label,$ms,$(hostname),$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$out"
}

# Hot path 1: hash the full evidence corpus (real files).
measure evidence_index_hash python3 - <<'PY'
import hashlib, pathlib
for p in pathlib.Path('.agent/state/evidence').rglob('*'):
    if p.is_file():
        hashlib.sha256(p.read_bytes()).hexdigest()
PY

# Hot path 2: release claims gate under full profile.
measure release_claims env WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh

# Hot path 3: production readiness structural check.
measure production_readiness python3 scripts/production_readiness.py

# Hot path 4: verify SHA256SUMS over the physical release artifacts.
measure checksum_verify sh -c 'cd release/wiremudder/candidate && sha256sum -c SHA256SUMS'

echo "--- raw performance evidence ---"
cat "$out"

python3 - "$out" <<'PY'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1])))
budget = 30000  # 30s p95 budget per operation on this host
for r in rows:
    ms = int(r['wall_ms'])
    assert ms < budget, f"{r['operation']} exceeded budget: {ms}ms"
    print(f"{r['operation']}: {ms}ms ok")
print('performance budget: ok')
PY
