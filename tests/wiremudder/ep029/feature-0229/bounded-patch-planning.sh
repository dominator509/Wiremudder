#!/usr/bin/env sh
# WM-FEAT-0229: bounded autonomous patch planning and validation.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "feature-0229: FAIL - $1" >&2; exit 1; }

grep -q "WM-FEAT-0229" .agent/features/FEATURES.tsv || fail "feature missing from FEATURES.tsv"

# Patch plans are subsystem-scoped and carry a validation command; the
# scope gate is enforced in code and covered by tests.
grep -q "pub fn subsystem_scoped" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "subsystem-scope gate missing from crate"
grep -q "fn patch_plan_must_be_subsystem_scoped" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "scope unit test missing"
grep -q "validation_command" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "validation command missing from patch plan"

# Independent review is required before the plan can proceed (no
# self-certification).
grep -q "reviewer must differ from the planner" wirecore/crates/wire-bug-automation/src/lib.rs \
  || fail "independent-review gate missing from crate"

echo "feature-0229: ok"
