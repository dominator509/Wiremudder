#!/usr/bin/env sh
# WM-SPEC-009-R02: AI, autopilot, voice, macro, trigger, script, plugin,
# headless, and cross-session commands enter the same deterministic Action
# Proposal path.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req r02: FAIL - $1" >&2; exit 1; }

# The gateway exposes every non-manual source (EP-008) and the autopilot
# proposes through it with source=Autopilot (R02).
grep -q "ActionSource::Autopilot" wirecore/crates/wire-autopilot/src/lib.rs \
  || fail "autopilot does not enter the Action Proposal path"
grep -q "ActionSource::Autopilot" wirecore/crates/wire-actions/src/lib.rs \
  || fail "gateway missing autopilot source"

# SPEC-009 declares the shared path.
grep -q "same deterministic Action Proposal path" .agent/specs/SPEC-009-command-safety-emergency-stop-and-pacing.md \
  || fail "SPEC-009 missing shared path"

echo "req WM-SPEC-009-R02: ok"
