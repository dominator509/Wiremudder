#!/usr/bin/env sh
# EP-009 M1 contract test: ownership + fence integrity for the node.
# Fails if the node contract, fences, or owned-feature list are broken.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/node-contracts/EP-009.md ] || fail "node contract missing"
[ -f .agent/expected-files/EP-009.txt ] || fail "static fence missing"
[ -f .agent/expected-files/EP-009.discovered.txt ] || fail "discovered amendment missing"
for m in M1 M2 M3 M4 M5; do
  [ -f ".agent/milestone-files/EP-009-$m.txt" ] || fail "milestone fence $m missing"
done

# Every owned feature must appear in the contract
for f in WM-FEAT-0002 WM-FEAT-0005 WM-FEAT-0006 WM-FEAT-0007 WM-FEAT-0008 \
         WM-FEAT-0009 WM-FEAT-0010 WM-FEAT-0013 WM-FEAT-0014 WM-FEAT-0015 \
         WM-FEAT-0016 WM-FEAT-0017 WM-FEAT-0020; do
  grep -q "$f" .agent/node-contracts/EP-009.md || fail "owned $f missing from contract"
done

# Every owned requirement must appear in the contract
for r in WM-SPEC-007-R01 WM-SPEC-007-R05 WM-SPEC-007-R06 WM-SPEC-007-R07 \
         WM-SPEC-007-R08 WM-SPEC-008-R06 WM-SPEC-008-R09 WM-SPEC-008-R10; do
  grep -q "$r" .agent/node-contracts/EP-009.md || fail "owned $r missing from contract"
done

echo "contract EP-009 ownership: ok"
