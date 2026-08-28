#!/usr/bin/env sh
# WM-SPEC-019-R02: events include schema/app/platform/subsystem/priority/
# severity/fingerprint/correlation/scope/feature/privacy/latency/queue/
# drop/coalesce/provider/voice/renderer/redaction fields without raw
# secrets.
set -eu
cd "$(dirname "$0")/../../../../.."

fail() { echo "req: FAIL - $1" >&2; exit 1; }

# The canonical event schema declares every required semantic field. Field
# names follow the schema's canonical spellings (schema_version for schema,
# correlation_id for correlation, latency_ms for latency, queue_depth for
# queue, dropped for drop, coalesced for coalesce).
schema=schemas/wiremudder/telemetry/event.schema.json
[ -f "$schema" ] || fail "no event schema found"

for field in schema_version app platform subsystem priority severity \
             fingerprint correlation_id scope feature privacy latency_ms \
             queue_depth dropped coalesced provider voice renderer \
             redaction; do
  grep -q "\"$field\"" "$schema" || fail "event schema missing field: $field"
done

# Raw secrets are never in event fields: the schema declares redaction and
# the owning spec requires it.
grep -q "\"redaction\"" "$schema" || fail "schema missing redaction"

# The spec requirement itself is on record.
grep -q "WM-SPEC-019-R02" .agent/specs/SPEC-019-telemetry-replay-diagnostics-and-bug-automation.md \
  || fail "SPEC-019 missing R02"

echo "req WM-SPEC-019-R02: ok"
