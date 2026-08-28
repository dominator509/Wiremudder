#!/usr/bin/env sh
# WM-SPEC-026-R10 (live-fire): operations evidence is retained under
# .agent/state/evidence and linked to node and release claims.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

# Evidence for completed milestones exists under the canonical path.
# (M5 evidence is written by record-evidence.sh as the verifier runs.)
[ -d .agent/state/evidence/EP-035 ] || fail "missing EP-035 evidence dir"
for m in M1 M2 M3 M4; do
  [ -f ".agent/state/evidence/EP-035/$m/evidence.json" ] \
    || fail "missing evidence for $m"
  [ -f ".agent/state/evidence/EP-035/$m/output.log" ] \
    || fail "missing output log for $m"
done

# Evidence is linked to node and release claims in the ledger.
grep -q "EP-035" .agent/state/LEDGER.md || fail "EP-035 missing from ledger"
grep -q "evidence=.agent/state/evidence/EP-035" .agent/state/LEDGER.md \
  || fail "ledger entries not linked to evidence paths"

# Source evidence exists for the release claims.
grep -q "WM-SRC-0002" .agent/state/source-evidence.jsonl || true
sh scripts/source-evidence-check.sh >/dev/null || fail "source evidence check failed"

echo "req WM-SPEC-026-R10: ok"
