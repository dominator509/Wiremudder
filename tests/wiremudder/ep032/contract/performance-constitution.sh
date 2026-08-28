#!/usr/bin/env sh
# EP-032 M1 contract test: the performance constitution anchors this node
# must enforce exist and are binding: the Prime Directive, priority rings,
# target budgets, required fixtures, and the R12/R06 evidence rules.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f PERFORMANCE_CONSTITUTION.md ] || fail "missing PERFORMANCE_CONSTITUTION.md"
[ -f .agent/specs/SPEC-004-performance-constitution-and-degradation.md ] \
  || fail "missing SPEC-004"

# Prime Directive.
grep -q "Prime Directive" PERFORMANCE_CONSTITUTION.md || fail "constitution missing prime directive"
grep -q "Raw MUD text, manual input, connection health, command send, and emergency stop are sacred" \
  PERFORMANCE_CONSTITUTION.md || fail "constitution prime directive text missing"

# Priority rings R01..R05.
for r in WM-SPEC-004-R01 WM-SPEC-004-R02 WM-SPEC-004-R03 WM-SPEC-004-R04 WM-SPEC-004-R05; do
  grep -q "$r" .agent/specs/SPEC-004-performance-constitution-and-degradation.md \
    || fail "spec missing $r"
done

# Target budgets R11.
grep -q "WM-SPEC-004-R11" .agent/specs/SPEC-004-performance-constitution-and-degradation.md \
  || fail "spec missing WM-SPEC-004-R11"
grep -q "input under 5 ms" .agent/specs/SPEC-004-performance-constitution-and-degradation.md \
  || fail "spec missing 5ms input budget"
grep -q "emergency stop under 10 ms" .agent/specs/SPEC-004-performance-constitution-and-degradation.md \
  || fail "spec missing 10ms emergency stop budget"

# Required fixtures.
grep -q "Required Fixtures" PERFORMANCE_CONSTITUTION.md || fail "constitution missing required fixtures"
for fx in "Text flood" "ANSI spam" "trigger storm" "pathological regex" "mapper pathfinding" \
          "multi-session fairness" "emergency stop under load"; do
  grep -q "$fx" PERFORMANCE_CONSTITUTION.md || fail "constitution missing fixture $fx"
done

# R12/R06 evidence rules (this node's owned requirements).
grep -q "WM-SPEC-004-R12" .agent/specs/SPEC-004-performance-constitution-and-degradation.md \
  || fail "spec missing WM-SPEC-004-R12"
grep -q "WM-SPEC-027-R06" .agent/specs/SPEC-027-testing-oracles-performance-and-platform-certification.md \
  || fail "spec missing WM-SPEC-027-R06"

echo "contract EP-032 performance-constitution: ok"
