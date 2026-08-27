#!/usr/bin/env sh
# E2E test: complete fork-governance flow — remotes unambiguous, patch
# classification works on real commits, upstream provenance verified,
# and a sync drill rolls back cleanly with green tags intact.
set -eu
. ./.env

echo "e2e: verifying remotes"
up=$(git config --get remote.upstream.url)
or=$(git config --get remote.origin.url)
[ -n "$up" ] && [ -n "$or" ] || { echo "FAIL: remotes incomplete" >&2; exit 1; }

echo "e2e: classifying recent governance commits"
for rev in HEAD HEAD~1 HEAD~2; do
  cls=$(python3 tests/wiremudder/ep002/unit/classify_patch.py "$rev" 'governance drill')
  case "$cls" in
    graphlock|unclassified) ;;
    *) echo "FAIL: unexpected classification $cls for $rev" >&2; exit 1 ;;
  esac
done

echo "e2e: upstream provenance"
git fetch upstream development >/dev/null 2>&1 || { echo "FAIL: fetch" >&2; exit 1; }
pinned=$(awk '/development_commit:/{gsub(/"/,""); print $2}' UPSTREAM.lock.yaml)
mb=$(git merge-base HEAD upstream/development)
[ "$mb" = "$pinned" ] || { echo "FAIL: merge-base $mb != $pinned" >&2; exit 1; }

echo "e2e: sync drill rollback"
base=$(git rev-parse HEAD)
branch="sync/drill-e2e-$$"
trap 'git checkout -q "$base" 2>/dev/null || true; git branch -D "$branch" >/dev/null 2>&1 || true' EXIT
git checkout -q -b "$branch" "$base"
git merge --no-edit "$base" >/dev/null 2>&1
git checkout -q "$base"
git branch -D "$branch" >/dev/null 2>&1 || true
trap - EXIT
git rev-parse -q --verify "refs/tags/green/EP-001" >/dev/null || { echo "FAIL: green/EP-001 lost" >&2; exit 1; }
[ "$(git rev-parse HEAD)" = "$base" ] || { echo "FAIL: HEAD moved" >&2; exit 1; }

echo "e2e fork-governance: ok"
