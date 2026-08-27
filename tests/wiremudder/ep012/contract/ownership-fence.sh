#!/usr/bin/env sh
# EP-012 M1 contract test: ownership + fence integrity for the node.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-012.md ] || fail "node contract missing"
[ -f .agent/expected-files/EP-012.txt ] || fail "static fence missing"
[ -f .agent/expected-files/EP-012.discovered.txt ] || fail "discovered amendment missing"
for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-012-$m.txt" ] || fail "milestone fence $m missing"
done

for f in WM-FEAT-0001 WM-FEAT-0003 WM-FEAT-0004 WM-FEAT-0011 WM-FEAT-0012 \
         WM-FEAT-0018 WM-FEAT-0019 WM-FEAT-0021; do
  grep -q "$f" .agent/node-contracts/EP-012.md || fail "owned $f missing from contract"
done

echo "contract EP-012 ownership: ok"
