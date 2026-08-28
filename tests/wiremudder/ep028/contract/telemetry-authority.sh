#!/usr/bin/env sh
# EP-028 M1 contract test: telemetry authority and boundary declarations.
# Telemetry is off by default (WM-SPEC-019-R01), events conform to the
# canonical telemetry schema (WM-SPEC-019-R02), and no hosted telemetry
# endpoint is required (WM-SPEC-026-R08). Fails when an authorized
# boundary, owned feature, or owned requirement is absent from the node
# contract or static fence, or when the live-fire proof is not specified.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Authorized boundaries must appear in the node contract and static fence.
for b in src/wiremudder/ui/diagnostics/ wirecore/crates/wire-telemetry/ \
         wirecore/crates/wire-replay/ schemas/wiremudder/telemetry/; do
  grep -q "$b" .agent/node-contracts/EP-028.md || fail "authorized boundary $b missing from EP-028 contract"
  grep -q "$b" .agent/expected-files/EP-028.txt || fail "boundary $b missing from static fence"
done

# Owned features must appear in the contract.
for f in WM-FEAT-0128 WM-FEAT-0132 WM-FEAT-0221 WM-FEAT-0223 WM-FEAT-0224 \
         WM-FEAT-0225 WM-FEAT-0227; do
  grep -q "$f" .agent/node-contracts/EP-028.md || fail "owned $f missing from EP-028 contract"
done

# Owned requirements must appear in the contract.
for r in WM-SPEC-011-R03 WM-SPEC-011-R10 WM-SPEC-019-R01 WM-SPEC-019-R03 \
         WM-SPEC-023-R05 WM-SPEC-024-R09 WM-SPEC-025-R02 WM-SPEC-026-R07 \
         WM-SPEC-026-R08; do
  grep -q "$r" .agent/node-contracts/EP-028.md || fail "owned $r missing from EP-028 contract"
done

# The live-fire proof must be specified.
grep -q "LF-028" .agent/node-contracts/EP-028.md || fail "LF-028 missing from EP-028 contract"
grep -q "tests/live-fire/LF-028-diagnostic-bundle-redaction.sh" .agent/expected-files/EP-028.txt \
  || fail "LF-028 path missing from static fence"

# Telemetry off by default and bounded crash-safe ring buffers (SPEC-019-R01).
grep -q "WM-SPEC-019-R01: Telemetry is off by default" \
  .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md \
  || fail "telemetry-off-default rule missing from SPEC-019"

# No hosted telemetry endpoint required (SPEC-026-R08).
grep -q "WM-SPEC-026-R08: No hosted telemetry" \
  .agent/specs/SPEC-026-observability-operations-and-diagnostics.md \
  || fail "no-hosted-telemetry rule missing from SPEC-026"

echo "contract EP-028 telemetry-authority: ok"
