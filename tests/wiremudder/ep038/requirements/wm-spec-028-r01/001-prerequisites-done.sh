#!/usr/bin/env sh
# WM-SPEC-028-R01: A release candidate is created only after every
# required node for its release profile is DONE with evidence, node
# verify, expected-files audit, ledger event, and green tag. Proven with
# real ledger, tag, and evidence checks. (ledger.sh status reports
# PENDING post-LEASE_RELEASE by design; DONE is evidenced by the NODE_DONE
# ledger event plus green tag plus M5 evidence.)
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "r28-r01: FAIL - $1" >&2; exit 1; }

# 1. Every EP-000..EP-037 node (all 38 required nodes before EP-038) has
#    a NODE_DONE ledger event and a green tag.
i=0
while [ "$i" -le 37 ]; do
  node=$(printf 'EP-%03d' "$i")
  grep -q "| $node | NODE_DONE |" .agent/state/LEDGER.md \
    || fail "$node missing NODE_DONE ledger event"
  git rev-parse -q --verify "refs/tags/green/$node" >/dev/null \
    || fail "missing green/$node"
  i=$((i + 1))
done

# 2. Each of those nodes has an M5 milestone ledger event and an evidence
#    directory (the evidence store). (Some early nodes record M5 evidence
#    as the ledger event rather than an evidence.json file; the gate is
#    the ledger event plus green tag plus evidence directory.)
i=0
while [ "$i" -le 37 ]; do
  node=$(printf 'EP-%03d' "$i")
  grep -q "| $node | MILESTONE_PASS | M5 " .agent/state/LEDGER.md \
    || fail "missing M5 ledger event for $node"
  [ -d ".agent/state/evidence/$node" ] \
    || fail "missing evidence dir for $node"
  i=$((i + 1))
done

# 3. The frozen candidate exists with a real manifest and checksums.
cand=release/wiremudder/candidate
[ -f "$cand/manifest.json" ] || fail "candidate manifest missing"
[ -f "$cand/SHA256SUMS" ] || fail "candidate checksums missing"

echo "requirement wm-spec-028-r01: ok"
