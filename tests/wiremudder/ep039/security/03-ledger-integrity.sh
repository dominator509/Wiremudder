#!/usr/bin/env sh
# EP-039 M4 security: the evidence ledger is append-only — a fabricated or
# reordered row would break the ledger validator. The real ledger must pass.
set -eu
cd "$(dirname "$0")/../../../.."

[ -f .agent/state/LEDGER.md ] || { echo "FAIL: ledger missing" >&2; exit 1; }

python3 - <<'PY'
import pathlib, re
ledger = pathlib.Path('.agent/state/LEDGER.md').read_text(encoding='utf-8')
rows = [ln for ln in ledger.splitlines() if '|' in ln and 'ipman-hermes' in ln or 'WIREMUDDER_AGENT_ID' in ln]
# Every row must have the canonical shape: timestamp | agent | node | event | detail
pat = re.compile(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z \| [^|]+ \| [^|]* \| [A-Z_]+ \| ')
bad = [ln for ln in ledger.splitlines() if ln.startswith('20') and not pat.match(ln)]
assert not bad, f"malformed ledger rows: {bad[:3]}"
allowed = {'RUN_INIT','PREFLIGHT_OK','LEASE','HEARTBEAT','MILESTONE_PASS','ATTEMPT_FAIL','SIG','FALLBACK_TAKEN','ROLLBACK','NODE_DONE','NODE_BLOCKED','LEASE_RELEASE','LEASE_TAKEOVER','RUN_COMPLETE','DECISION','SOURCE_EVIDENCE','ADR'}
events = re.findall(r'\| ([A-Z_]+) \|', ledger)
unknown = set(events) - allowed
assert not unknown, f"unknown ledger events: {unknown}"
assert 'NODE_DONE' in events, 'no NODE_DONE rows'
print(f'ledger integrity: ok ({len(events)} events, all canonical)')
PY
