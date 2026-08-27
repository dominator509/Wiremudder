#!/usr/bin/env sh
# Contract test: inherited build skill and presets must exist.
set -eu
[ -f .agents/skills/build-mudlet/SKILL.md ] || { echo "FAIL: build-mudlet skill missing" >&2; exit 1; }
cmake --list-presets 2>/dev/null | grep -Fq '"linux-debug-nosan"' || { echo "FAIL: linux-debug-nosan preset missing" >&2; exit 1; }
echo "contract build-skill-presets: ok"
