#!/usr/bin/env sh
# EP-013 M1 contract test: ownership + fence integrity for the node.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-013.md ] || fail "node contract missing"
[ -f .agent/expected-files/EP-013.txt ] || fail "static fence missing"
[ -f .agent/expected-files/EP-013.discovered.txt ] || fail "discovered amendment missing"
for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-013-$m.txt" ] || fail "milestone fence $m missing"
done

for f in WM-FEAT-0165 WM-FEAT-0166 WM-FEAT-0167 WM-FEAT-0168; do
  grep -q "$f" .agent/node-contracts/EP-013.md || fail "owned $f missing from contract"
done
for r in WM-SPEC-005-R07 WM-SPEC-012-R02 WM-SPEC-012-R03 WM-SPEC-012-R04 \
         WM-SPEC-012-R05 WM-SPEC-012-R10; do
  grep -q "$r" .agent/node-contracts/EP-013.md || fail "owned $r missing from contract"
done

# Authorized boundaries exist in the static fence.
for p in src/wiremudder/mapper/ wirecore/crates/wire-world-graph/ compatibility/maps/ schemas/wiremudder/world/; do
  grep -q "^$p$" .agent/expected-files/EP-013.txt || fail "authorized boundary missing from fence: $p"
done

echo "contract EP-013 ownership: ok"
