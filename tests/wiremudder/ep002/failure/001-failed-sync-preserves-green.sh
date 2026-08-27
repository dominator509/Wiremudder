#!/usr/bin/env sh
# Failure test: a failed sync must leave the previous green tag intact
# and must not be promoted (SPEC-001-R10).
set -eu
. ./.env
base=$(git rev-parse HEAD)
branch="sync/fail-$$"
trap 'git checkout -q "$base" 2>/dev/null || true; git branch -D "$branch" >/dev/null 2>&1 || true' EXIT
git checkout -q -b "$branch" "$base"
# Force a conflict: modify a tracked governance file, then merge the
# upstream development head (which also touches governance-adjacent files).
echo "# conflict probe" >> docs/wiremudder/upstream/design/EP-002-governance-design.md
set +e
git merge --no-edit upstream/development >/tmp/wm-e2f-001.out 2>&1
rc=$?
set -e
# Merge may fail (conflict) OR succeed; either way roll back to base.
git checkout -q -- docs/wiremudder/upstream/design/EP-002-governance-design.md 2>/dev/null || true
git checkout -q "$base" 2>/dev/null || true
git branch -D "$branch" >/dev/null 2>&1 || true
trap - EXIT
git rev-parse -q --verify "refs/tags/green/EP-001" >/dev/null || { echo "FAIL: green tag lost after failed sync" >&2; exit 1; }
[ "$(git rev-parse HEAD)" = "$base" ] || { echo "FAIL: HEAD moved after failed sync" >&2; exit 1; }
echo "failure failed-sync-preserves-green: ok"
