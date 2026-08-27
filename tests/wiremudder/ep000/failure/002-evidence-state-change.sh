#!/usr/bin/env sh
# Failure test: source-evidence recording must reject a command that
# changes repository state (read-only evidence invariant).
set -eu
newfile=probe-new-$$
trap 'rm -f "$newfile" /tmp/wm-fail-002.out' EXIT
rm -f "$newfile"
set +e
sh scripts/source-evidence-record.sh docs/ai-instructions.md "state probe" "probe" -- sh -c "echo x > '$newfile'" >/tmp/wm-fail-002.out 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: evidence record accepted state-changing command" >&2; exit 1; }
grep -q "changed repository state" /tmp/wm-fail-002.out || { echo "FAIL: expected state-change diagnostic missing" >&2; exit 1; }
echo "failure evidence-state-change: ok"
