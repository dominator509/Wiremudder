#!/usr/bin/env sh
# Contract test: upstream instructions and skills remain preserved.
set -eu
[ -f docs/ai-instructions.md ] || { echo "FAIL: docs/ai-instructions.md missing" >&2; exit 1; }
sha=$(git show HEAD:docs/ai-instructions.md | sha256sum | cut -d' ' -f1)
[ "$sha" = "a6802bfeedc78802e085e70b443bbe4641f8d0fb662d69c5ade8abe8b39d8e7a" ] || { echo "FAIL: ai-instructions drift $sha" >&2; exit 1; }
[ -f .agents/skills/build-mudlet/SKILL.md ] || { echo "FAIL: build skill missing" >&2; exit 1; }
[ -f .agents/skills/open-pr/SKILL.md ] || { echo "FAIL: open-pr skill missing" >&2; exit 1; }
echo "contract upstream-preserved: ok"
