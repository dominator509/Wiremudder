#!/usr/bin/env sh
# Contract test: preserved upstream AI instructions must be intact.
set -eu
[ -f docs/ai-instructions.md ] || { echo "FAIL: docs/ai-instructions.md missing" >&2; exit 1; }
sha=$(git show HEAD:docs/ai-instructions.md | sha256sum | cut -d' ' -f1)
[ "$sha" = "a6802bfeedc78802e085e70b443bbe4641f8d0fb662d69c5ade8abe8b39d8e7a" ] || { echo "FAIL: docs/ai-instructions.md drift sha=$sha" >&2; exit 1; }
echo "contract ai-instructions: ok"
