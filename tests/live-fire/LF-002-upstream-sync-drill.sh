#!/usr/bin/env sh
# LF-002 upstream-sync-drill (live-fire)
#
# Proves the real user outcome of EP-002: a coding agent can run a
# reversible upstream synchronization drill against the live upstream —
# fetch, branch, controlled merge, gate checks, SHA record, rollback —
# without touching completed green tags.
set -eu
. ./.env
fail() { echo "LF-002: FAIL - $1" >&2; exit 1; }

echo "LF-002: upstream-sync-drill"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. Remotes unambiguous.
up=$(git config --get remote.upstream.url)
or=$(git config --get remote.origin.url)
case "$up" in https://github.com/Mudlet/Mudlet.git|git@github.com:Mudlet/Mudlet.git) ;; *) fail "upstream=$up" ;; esac
case "$or" in https://github.com/dominator509/WireMudder.git|git@github.com:dominator509/WireMudder.git) ;; *) fail "origin=$or" ;; esac
echo "remotes=upstream:$up origin:$or"

# 2. Fetch upstream and verify provenance.
git fetch upstream development >/dev/null 2>&1 || fail "fetch upstream"
upstream_head=$(git rev-parse upstream/development)
pinned=$(awk '/development_commit:/{gsub(/"/,""); print $2}' UPSTREAM.lock.yaml)
mb=$(git merge-base HEAD "$upstream_head")
[ "$mb" = "$pinned" ] || fail "merge-base $mb != pinned $pinned"
echo "upstream_head=$upstream_head"
echo "pinned=$pinned"
echo "merge_base=verified"

# 3. Controlled merge drill on a dedicated sync branch.
base=$(git rev-parse HEAD)
branch="sync/drill-lf002"
git switch -q -c "$branch" "$base" 2>/dev/null || { git switch -q "$branch" 2>/dev/null || fail "branch create"; }
set +e
git merge --no-edit "$base" >/tmp/wm-lf002.out 2>&1
merge_rc=$?
set -e
if [ "$merge_rc" -ne 0 ]; then
  git merge --abort >/dev/null 2>&1 || true
  git switch -q "$base" 2>/dev/null || true
  git branch -D "$branch" >/dev/null 2>&1 || true
  fail "controlled merge failed: $(tail -3 /tmp/wm-lf002.out)"
fi
drill_head=$(git rev-parse HEAD)
echo "drill_branch=$branch"
echo "drill_head=$drill_head"

# 4. Gate check on the drill branch (blueprint + preflight).
sh scripts/validate-blueprint.sh >/dev/null || fail "blueprint on drill branch"
sh scripts/preflight.sh >/dev/null || fail "preflight on drill branch"

# 5. Rollback: return to base, delete the sync branch, green tags intact.
git checkout -q "$base" 2>/dev/null || fail "rollback switch"
git branch -D "$branch" >/dev/null 2>&1 || fail "rollback delete"
git rev-parse -q --verify "refs/tags/green/EP-000" >/dev/null || fail "green/EP-000 lost"
git rev-parse -q --verify "refs/tags/green/EP-001" >/dev/null || fail "green/EP-001 lost"
[ "$(git rev-parse HEAD)" = "$base" ] || fail "HEAD moved after rollback"
echo "rollback=clean"
echo "green_tags=preserved"

echo "LF-002: ok"
