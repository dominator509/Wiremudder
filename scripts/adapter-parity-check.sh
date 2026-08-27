#!/usr/bin/env sh
set -eu
files='AGENTS.md CLAUDE.md GEMINI.md HERMES.md OPENCLAW.md .github/copilot-instructions.md .cursor/rules/wiremudder-graphlock.mdc .clinerules/wiremudder-graphlock.md'
base=
for f in $files; do
  [ -f "$f" ] || { echo "adapter parity: FAIL - missing $f" >&2; exit 1; }
  block=$(awk '/^PRIME-BLOCK-BEGIN$/{p=1} p{print} /^PRIME-BLOCK-END$/{exit}' "$f")
  [ -n "$block" ] || { echo "adapter parity: FAIL - missing block $f" >&2; exit 1; }
  sum=$(printf '%s\n' "$block" | cksum | awk '{print $1":"$2}')
  if [ -z "$base" ]; then base=$sum; elif [ "$sum" != "$base" ]; then echo "adapter parity: FAIL - $f differs" >&2; exit 1; fi
done
echo 'adapter parity: ok'
