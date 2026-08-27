#!/usr/bin/env sh
# Contract test: all Graphlock adapters carry byte-identical prime blocks.
set -eu
awk '/^PRIME-BLOCK-BEGIN$/{p=1} p{print} /^PRIME-BLOCK-END$/{if(p) exit}' AGENTS.md > /tmp/wm-c1-agents.$$
for f in CLAUDE.md .github/copilot-instructions.md; do
  awk '/^PRIME-BLOCK-BEGIN$/{p=1} p{print} /^PRIME-BLOCK-END$/{if(p) exit}' "$f" > /tmp/wm-c1-other.$$
  diff -q /tmp/wm-c1-agents.$$ /tmp/wm-c1-other.$$ >/dev/null || { echo "FAIL: prime block mismatch in $f" >&2; exit 1; }
done
rm -f /tmp/wm-c1-agents.$$ /tmp/wm-c1-other.$$
echo "contract prime-blocks: ok"
