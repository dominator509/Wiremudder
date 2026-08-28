#!/usr/bin/env sh
# EP-028 M1 contract test: data classification and retention declarations.
# Private, secret, diagnostic, voice, transcript, and public content use
# distinct data classifications and default retention (WM-SPEC-023-R05);
# retention and deletion cover diagnostics and replay fixtures
# (WM-SPEC-011-R10). The telemetry/replay boundaries must be declared in
# the contract and static fence before implementation.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Classification rule must be binding in SPEC-023.
grep -q "WM-SPEC-023-R05: Private, secret, diagnostic, voice, transcript, and public content use distinct data classifications and default retention" \
  .agent/specs/SPEC-023-data-model-and-retention.md \
  || fail "classification rule missing from SPEC-023"

# Retention coverage must include diagnostics and replay fixtures.
grep -q "WM-SPEC-011-R10: Retention and deletion cover transcripts, voice transcripts, AI events, diagnostics, replay fixtures, memory, and audit exceptions" \
  .agent/specs/SPEC-011-local-storage-transcripts-search-and-backup.md \
  || fail "retention rule missing from SPEC-011"

# Telemetry and replay boundaries must be authorized and fenced.
for b in wirecore/crates/wire-telemetry/ wirecore/crates/wire-replay/ \
         schemas/wiremudder/telemetry/; do
  grep -q "$b" .agent/node-contracts/EP-028.md || fail "authorized boundary $b missing from EP-028 contract"
  grep -q "$b" .agent/expected-files/EP-028.txt || fail "boundary $b missing from static fence"
done

# No new authority or secret access implied by this node.
grep -q "No new authority" .agent/node-contracts/EP-028.md \
  || fail "no-new-authority clause missing from EP-028 contract"

echo "contract EP-028 telemetry-classification: ok"
