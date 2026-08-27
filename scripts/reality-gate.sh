#!/usr/bin/env sh
set -eu
PAT=.agent/reality-patterns
ALLOW=.agent/reality-allow
[ -f "$PAT" ] && [ -f "$ALLOW" ] || { echo 'reality gate: FAIL - missing pattern files' >&2; exit 1; }
hits=0
for d in src/wiremudder wirecore schemas/wiremudder tools/wiremudder-*; do
  [ -e "$d" ] || continue
  out=$(grep -RInE -f "$PAT" "$d" 2>/dev/null | grep -vE -f "$ALLOW" || true)
  if [ -n "$out" ]; then printf '%s\n' "$out"; hits=1; fi
done
[ "$hits" -eq 0 ] || { echo 'reality gate: FAIL' >&2; exit 1; }
echo 'reality gate: ok'
