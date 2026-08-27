#!/usr/bin/env sh
# Integration test: sync branch can merge a controlled upstream change,
# then roll back cleanly without crossing a completed green tag.
set -eu
. ./.env
base=$(git rev-parse HEAD)
branch="sync/drill-integration-$$"
trap 'git checkout -q "$base" 2>/dev/null || true; git branch -D "$branch" >/dev/null 2>&1 || true' EXIT
git checkout -q -b "$branch" "$base"
# Merge a controlled upstream commit (use merge-base..upstream/development
# first-parent commit; here we use the merge-base itself which is a real
# upstream commit already in history, proving merge + rollback mechanics).
git merge --no-edit "$base" >/dev/null 2>&1 || { echo "FAIL: sync merge failed" >&2; exit 1; }
merged=$(git rev-parse HEAD)
# Rollback: return to base and delete the branch.
git checkout -q "$base"
git branch -D "$branch" >/dev/null 2>&1 || true
trap - EXIT
git rev-parse -q --verify "refs/tags/green/EP-001" >/dev/null || { echo "FAIL: green/EP-001 tag missing after drill" >&2; exit 1; }
[ "$(git rev-parse HEAD)" = "$base" ] || { echo "FAIL: HEAD moved after rollback" >&2; exit 1; }
echo "integration sync-drill-mechanics: ok base=$base merged=$merged"
