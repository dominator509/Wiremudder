#!/usr/bin/env sh
# EP-014 M1 contract test: ownership + fence integrity for the node.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-014.md ] || fail "node contract missing"
[ -f .agent/expected-files/EP-014.txt ] || fail "static fence missing"
[ -f .agent/expected-files/EP-014.discovered.txt ] || fail "discovered amendment missing"
for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-014-$m.txt" ] || fail "milestone fence $m missing"
done

for r in WM-SPEC-003-R08 WM-SPEC-010-R10 WM-SPEC-011-R04 WM-SPEC-011-R06 \
         WM-SPEC-011-R07 WM-SPEC-011-R08 WM-SPEC-023-R08 WM-SPEC-024-R02 \
         WM-SPEC-026-R04 WM-SPEC-026-R05 WM-SPEC-026-R06; do
  grep -q "$r" .agent/node-contracts/EP-014.md || fail "owned $r missing from contract"
done

# Authorized boundaries exist in the static fence.
for p in wirecore/crates/wire-storage/ wirecore/migrations/ schemas/wiremudder/storage/ tools/wiremudder-backup/; do
  grep -q "^$p$" .agent/expected-files/EP-014.txt || fail "authorized boundary missing from fence: $p"
done

echo "contract EP-014 ownership: ok"
