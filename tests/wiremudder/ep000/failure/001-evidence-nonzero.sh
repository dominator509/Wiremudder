#!/usr/bin/env sh
# Failure test: source-evidence recording must fail when the evidence
# command exits non-zero, and must not append a ledger record.
set -eu
before=$(wc -l < .agent/state/source-evidence.jsonl)
set +e
sh scripts/source-evidence-record.sh docs/ai-instructions.md "failure probe" "probe" -- sh -c 'echo probe output; exit 3' >/tmp/wm-fail-001.out 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: evidence record accepted non-zero exit" >&2; exit 1; }
after=$(wc -l < .agent/state/source-evidence.jsonl)
[ "$before" = "$after" ] || { echo "FAIL: ledger grew on failed evidence" >&2; exit 1; }
echo "failure evidence-nonzero: ok"
