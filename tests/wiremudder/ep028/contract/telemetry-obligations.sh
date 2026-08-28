#!/usr/bin/env sh
# EP-028 M1 contract test: the six acceptance obligations of the node
# contract must be declared as binding requirements before product work:
# 1. Telemetry remains off externally by default.
# 2. Ring buffers are bounded.
# 3. Redaction corpus passes.
# 4. Replay is deterministic.
# 5. Bundle preview matches exported content.
# 6. No secret or private data leaks.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Obligations must be stated in the node contract.
for ob in "Telemetry remains off externally by default" \
          "Ring buffers are bounded" \
          "Redaction corpus passes" \
          "Replay is deterministic" \
          "Bundle preview matches exported content" \
          "No secret or private data leaks"; do
  grep -qF "$ob" .agent/node-contracts/EP-028.md || fail "obligation missing from EP-028 contract: $ob"
done

# Crash/diagnostic bundles are local, redacted, previewable,
# content-addressed, never submitted without explicit user action
# (WM-SPEC-019-R03).
grep -q "WM-SPEC-019-R03: Crash and diagnostic bundles are local, redacted, previewable, content-addressed" \
  .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md \
  || fail "bundle rule missing from SPEC-019"

# Support bundles are previewable, redacted, reproducible, content-addressed
# (WM-SPEC-026-R07).
grep -q "WM-SPEC-026-R07: Support bundles are previewable, redacted, reproducible, and content-addressed" \
  .agent/specs/SPEC-026-observability-operations-and-diagnostics.md \
  || fail "support-bundle rule missing from SPEC-026"

# Restart resynchronizes snapshots rather than unbounded raw history
# (WM-SPEC-024-R09).
grep -q "WM-SPEC-024-R09: Restart resynchronizes snapshots rather than replaying unbounded raw history" \
  .agent/specs/SPEC-024-bridge-ipc-api-and-headless-contracts.md \
  || fail "snapshot-resync rule missing from SPEC-024"

echo "contract EP-028 telemetry-obligations: ok"
