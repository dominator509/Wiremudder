#!/usr/bin/env sh
# EP-011 M1 contract test: ownership + fence integrity for the node.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-011.md ] || fail "node contract missing"
[ -f .agent/expected-files/EP-011.txt ] || fail "static fence missing"
[ -f .agent/expected-files/EP-011.discovered.txt ] || fail "discovered amendment missing"
for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-011-$m.txt" ] || fail "milestone fence $m missing"
done

for f in WM-FEAT-0022 WM-FEAT-0023 WM-FEAT-0024 WM-FEAT-0025 WM-FEAT-0026 \
         WM-FEAT-0027 WM-FEAT-0028 WM-FEAT-0029 WM-FEAT-0030 WM-FEAT-0031 \
         WM-FEAT-0032 WM-FEAT-0033 WM-FEAT-0034 WM-FEAT-0035 WM-FEAT-0036; do
  grep -q "$f" .agent/node-contracts/EP-011.md || fail "owned $f missing from contract"
done

echo "contract EP-011 ownership: ok"
