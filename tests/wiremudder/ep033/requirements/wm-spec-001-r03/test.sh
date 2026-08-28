#!/usr/bin/env sh
# EP-033 M5 requirement test: WM-SPEC-001-R03 — EP-000 verifies the locked
# commit, license files, submodules, build instructions, agent instructions,
# and current source layout before edits.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "requirement: FAIL - $1" >&2; exit 1; }

# EP-000 baseline verification anchors exist: pinned upstream lock, GPL
# license file, submodule table, build instructions, agent instructions.
[ -f UPSTREAM.lock.yaml ] || fail "missing UPSTREAM.lock.yaml"
grep -q "development_commit" UPSTREAM.lock.yaml || fail "missing pinned commit"
[ -f COPYING ] || fail "missing COPYING"
[ -f .gitmodules ] || fail "missing .gitmodules"
[ -f docs/ai-instructions.md ] || fail "missing build/agent instructions"
[ -f .agents/skills/build-mudlet/SKILL.md ] || fail "missing build skill"

echo "requirement WM-SPEC-001-R03: ok"
