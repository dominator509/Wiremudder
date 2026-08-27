#!/usr/bin/env sh
# LF-000 upstream-baseline-discovery (live-fire)
#
# Proves the real user outcome of EP-000: a coding agent can bootstrap
# from the pinned Mudlet-derived repository, run the discovery gates, and
# obtain a machine-readable evidence baseline before any product edit.
# Every step runs against the live repository and prints observed facts.
set -eu
. ./.env
fail() { echo "LF-000: FAIL - $1" >&2; exit 1; }

echo "LF-000: upstream-baseline-discovery"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. Pinned commit is present and is an ancestor of HEAD.
commit=$WIREMUDDER_UPSTREAM_COMMIT
git cat-file -e "$commit^{commit}" || fail "pinned commit $commit missing"
git merge-base --is-ancestor "$commit" HEAD || fail "pinned commit not ancestor of HEAD"
echo "pinned_commit=$commit"

# 2. Upstream remote points at the official Mudlet repository.
url=$(git config --get remote.upstream.url)
[ "$url" = "https://github.com/Mudlet/Mudlet.git" ] || fail "upstream remote mismatch: $url"
echo "upstream_remote=$url"

# 3. Working branch preserves upstream history.
head_commit=$(git rev-parse HEAD)
echo "head_commit=$head_commit"
echo "history_retained=$(git rev-list --count "$commit"..HEAD)"

# 4. Discovery gates pass against the live tree.
out=$(sh scripts/validate-blueprint.sh 2>&1) || fail "validate-blueprint"
echo "$out" | grep -q "blueprint validation: ok" || fail "blueprint sentinel"
out=$(sh scripts/preflight.sh 2>&1) || fail "preflight"
echo "$out" | grep -q "preflight: ok" || fail "preflight sentinel"
# EP-000 must be either the current dispatch or already green (graph advance).
if ! sh scripts/graph-next.sh | grep -q "EP-000"; then
  git rev-parse -q --verify "refs/tags/green/EP-000" >/dev/null || fail "EP-000 not active and not green"
fi
echo "ep000_state=green_or_active"

# 5. Evidence baseline is machine-readable and hash-verified.
evidence_count=$(wc -l < .agent/state/source-evidence.jsonl)
[ "$evidence_count" -ge 18 ] || fail "insufficient evidence"
python3 - <<'PY' || fail "evidence chain"
import hashlib, json
from pathlib import Path
rows = [json.loads(l) for l in Path('.agent/state/source-evidence.jsonl').read_text().splitlines() if l.strip()]
for r in rows:
    p = Path(r['output_path'])
    assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest() == r['output_sha256']
PY
echo "evidence_records=$evidence_count"

# 6. Upstream tree inventory is complete and deterministic.
tree_count=$(wc -l < .agent/state/upstream-tree.tsv)
[ "$tree_count" -gt 1000 ] || fail "inventory incomplete"
echo "inventory_paths=$((tree_count - 1))"

# 7. Command lock is populated and valid.
sh scripts/command-lock-check.sh >/dev/null || fail "command lock"
echo "command_lock_rows=$(grep -vc '^key' .agent/state/COMMANDS.lock.tsv)"

# 8. Stable release reference is recorded.
grep -q 'Mudlet-4.22.0' UPSTREAM.lock.yaml || fail "stable release missing"
echo "stable_release=Mudlet-4.22.0"

echo "LF-000: ok"
