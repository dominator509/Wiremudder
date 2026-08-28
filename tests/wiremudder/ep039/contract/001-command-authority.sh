#!/usr/bin/env sh
# EP-039 M1 contract: the discovered-path amendment must authorize the
# command authority (docs/ai-instructions.md) and every locked ship-gate
# command must be documented there verbatim before the gate can run.
set -eu

fail() { echo "ep039 contract: FAIL - $1" >&2; exit 1; }

[ -f docs/ai-instructions.md ] || fail "docs/ai-instructions.md missing"
grep -q "## WireMudder ship-gate commands" docs/ai-instructions.md \
  || fail "ship-gate command section missing from docs/ai-instructions.md"

# Every locked command must appear verbatim in the documented authority.
[ -f .agent/state/COMMANDS.lock.tsv ] || fail "COMMANDS.lock.tsv missing"
first=1
while IFS=$'\t' read -r key command evidence_id owner platform verified_at; do
  if [ "$first" -eq 1 ]; then first=0; continue; fi
  [ -n "$key" ] || continue
  # EP-039-owned commands must be documented in the command authority.
  [ "$owner" = "EP-039" ] || continue
  grep -qF -- "$command" docs/ai-instructions.md \
    || fail "locked command for $key absent from docs/ai-instructions.md"
  grep -q "$evidence_id" .agent/state/source-evidence.jsonl \
    || fail "evidence $evidence_id missing from source evidence"
done < .agent/state/COMMANDS.lock.tsv

echo "ep039 contract command-authority: ok"
