#!/usr/bin/env sh
set -eu
[ -f .env ] && { set -a; . ./.env; set +a; }
repo=${WIREMUDDER_UPSTREAM_REPO:-}
commit=${WIREMUDDER_UPSTREAM_COMMIT:-}
[ -n "$repo" ] && [ -n "$commit" ] || { echo 'upstream lock: FAIL - env values missing' >&2; exit 1; }
[ -d .git ] || { echo 'upstream lock: FAIL - not a Git repository' >&2; exit 1; }
git cat-file -e "$commit^{commit}" 2>/dev/null || { echo 'upstream lock: FAIL - commit absent' >&2; exit 1; }
git merge-base --is-ancestor "$commit" HEAD || { echo 'upstream lock: FAIL - locked commit is not an ancestor of HEAD' >&2; exit 1; }
[ -f docs/ai-instructions.md ] || { echo 'upstream lock: FAIL - missing upstream instructions' >&2; exit 1; }
[ -f .agents/skills/build-mudlet/SKILL.md ] || { echo 'upstream lock: FAIL - missing build skill' >&2; exit 1; }
[ -f CMakePresets.json ] && [ -f CMakeLists.txt ] && [ -d src ] || { echo 'upstream lock: FAIL - source tree incomplete' >&2; exit 1; }
echo 'upstream lock: ok'
