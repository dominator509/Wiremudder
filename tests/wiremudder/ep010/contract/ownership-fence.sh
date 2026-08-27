#!/usr/bin/env sh
# EP-010 M1 contract test: ownership + fence integrity for the node.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-010.md ] || fail "node contract missing"
[ -f .agent/expected-files/EP-010.txt ] || fail "static fence missing"
[ -f .agent/expected-files/EP-010.discovered.txt ] || fail "discovered amendment missing"
for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-010-$m.txt" ] || fail "milestone fence $m missing"
done

for f in WM-FEAT-0098 WM-FEAT-0103 WM-FEAT-0104 WM-FEAT-0105 WM-FEAT-0110 \
         WM-FEAT-0113 WM-FEAT-0114 WM-FEAT-0115 WM-FEAT-0116 WM-FEAT-0117 \
         WM-FEAT-0118 WM-FEAT-0119; do
  grep -q "$f" .agent/node-contracts/EP-010.md || fail "owned $f missing from contract"
done

for r in WM-SPEC-008-R01 WM-SPEC-008-R03 WM-SPEC-008-R04 WM-SPEC-008-R05 \
         WM-SPEC-020-R05 WM-SPEC-021-R04 WM-SPEC-022-R01 WM-SPEC-022-R02 \
         WM-SPEC-022-R05; do
  grep -q "$r" .agent/node-contracts/EP-010.md || fail "owned $r missing from contract"
done

echo "contract EP-010 ownership: ok"
