#!/usr/bin/env sh
# Performance test: sync drill (branch + merge + rollback) is bounded.
set -eu
. ./.env
base=$(git rev-parse HEAD)
branch="sync/perf-$$"
trap 'git checkout -q "$base" 2>/dev/null || true; git branch -D "$branch" >/dev/null 2>&1 || true' EXIT
start=$(date +%s%N)
git checkout -q -b "$branch" "$base"
git merge --no-edit "$base" >/dev/null 2>&1
git checkout -q "$base"
git branch -D "$branch" >/dev/null 2>&1 || true
end=$(date +%s%N)
ms=$(( (end - start) / 1000000 ))
trap - EXIT
echo "performance sync-drill: ${ms}ms"
[ "$ms" -lt 30000 ] || { echo "FAIL: sync drill too slow" >&2; exit 1; }
echo "performance sync-drill: ok"
