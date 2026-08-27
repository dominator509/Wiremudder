#!/usr/bin/env sh
# Integration test: a controlled upstream change can be fetched and its
# provenance verified (SPEC-001-R09: before/after SHAs recorded).
set -eu
before=$(git rev-parse HEAD)
git fetch upstream development >/dev/null 2>&1 || { echo "FAIL: cannot fetch upstream" >&2; exit 1; }
upstream_head=$(git rev-parse upstream/development)
git cat-file -e "$upstream_head^{commit}" || { echo "FAIL: upstream head not present" >&2; exit 1; }
# The merge-base must be our pinned commit (our fork descends from it).
mb=$(git merge-base HEAD "$upstream_head")
pinned=$(awk '/development_commit:/{gsub(/"/,""); print $2}' UPSTREAM.lock.yaml)
[ "$mb" = "$pinned" ] || { echo "FAIL: merge-base $mb != pinned $pinned" >&2; exit 1; }
echo "integration upstream-provenance: ok before=$before upstream=$upstream_head"
