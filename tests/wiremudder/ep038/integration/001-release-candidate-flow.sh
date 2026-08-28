#!/usr/bin/env sh
# EP-038 M3 integration test: the real release-candidate flow — frozen
# artifacts, manifest completeness, checksum verification, oracle
# decisions, and the release-claims gate all agree.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

oracle=wirecore/target/release/wire-release-oracle
[ -x "$oracle" ] || fail "oracle binary missing"

cand=release/wiremudder/candidate

# 1. Manifest is valid JSON and carries the exact channel/version.
python3 -c "import json,sys; json.load(open('$cand/manifest.json'))" || fail "manifest invalid JSON"
grep -q '"channel": "canary"' "$cand/manifest.json" || fail "manifest channel not canary"
grep -q '"version": "0.9.0-rc1"' "$cand/manifest.json" || fail "manifest version wrong"

# 2. Candidate completeness: the oracle certifies the frozen set.
"$oracle" candidate-check "$cand/manifest.json" | grep -q "candidate-complete" \
  || fail "candidate not complete"

# 3. Every content artifact listed in SHA256SUMS verifies against real bytes.
(cd "$cand" && sha256sum -c SHA256SUMS >/dev/null) || fail "checksum verification failed"

# 4. Manifest artifact hashes agree with SHA256SUMS for the same files.
python3 - <<'PY' || fail "manifest/checksum hash disagreement"
import hashlib, json
from pathlib import Path
cand = Path('release/wiremudder/candidate')
manifest = json.loads((cand/'manifest.json').read_text())
sums = {}
for line in (cand/'SHA256SUMS').read_text().splitlines():
    h, name = line.split('  ')
    sums[name] = h
for art in manifest['artifacts']:
    if art['name'] not in sums:
        raise SystemExit(f"artifact {art['name']} missing from SHA256SUMS")
    if art['sha256'] != sums[art['name']]:
        raise SystemExit(f"hash mismatch for {art['name']}")
    actual = hashlib.sha256((cand/art['name']).read_bytes()).hexdigest()
    if actual != art['sha256']:
        raise SystemExit(f"on-disk hash mismatch for {art['name']}")
print("integration: manifest-SHA256SUMS-disk agreement ok")
PY

# 5. Release claims gate: every feature has exactly one claim row and each
#    claim carries a real evidence path when the feature is implemented.
#    This node freezes the FULL release candidate; the claims gate is
#    therefore evaluated under the full profile.
WIREMUDDER_RELEASE_PROFILE=full sh scripts/release-claims-check.sh >/dev/null \
  || fail "release claims check failed"

# 6. Source archive is reproducible from the recorded source commit.
actual=$(/usr/bin/git archive --format=tar.gz "$(python3 -c "import json;print(json.load(open('$cand/manifest.json'))['source_commit'])")" | sha256sum | cut -d' ' -f1)
recorded=$(python3 -c "import json;[print(a['sha256']) for a in json.load(open('$cand/manifest.json'))['artifacts'] if a['name']=='source.tar.gz']")
[ "$actual" = "$recorded" ] || fail "source archive not reproducible: got $actual want $recorded"

echo "integration EP-038 release-candidate-flow: ok"
