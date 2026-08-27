# WireMudder Compatibility Oracle — design (EP-003)

## Purpose

The Compatibility Lab (SPEC-019-R07) and Protocol Museum (SPEC-019-R08)
provide an independent reference harness so implementation tests and the
thing they test cannot share the same hallucination (ADR-0004).

## Components

- `schemas/wiremudder/replay/session-replay.schema.json` — stable replay
  document contract (SPEC-019-R04).
- `compatibility/replay/replay_validate.py` — structural validator:
  required fields, event kinds, monotonic seq/t, 40-hex git_sha.
- `compatibility/protocol-museum/museum.py` — controlled fake MUD servers
  with scenarios: negotiation (IAC WILL), text-stream, malformed bytes,
  latency, disconnect.
- `compatibility/framework/sanitize.py` — deterministic secret and
  player-name stripping (SPEC-019-R05).
- `tools/protocol-museum/oracle_record.py` — real TCP capture into a
  sanitized, validated replay document.

## Oracle Flow

1. Start a museum fake server on 127.0.0.1.
2. Connect a real TCP client, capture lines for a bounded duration.
3. Sanitize (secrets, player names, credentials).
4. Validate against the replay schema.
5. Compare runs for determinism (differential).

## Invariants

- Replay seq strictly increasing; t monotonic.
- client_version.git_sha is 40 hex (reproducibility).
- Sanitized output contains no api_key/password/token/AKIA material.
- Deterministic scenarios produce identical line streams across runs.
- No raw secrets, full prompts, or private transcripts in fixtures.

## Boundaries

- New code is namespaced under compatibility/, tools/protocol-museum/,
  schemas/wiremudder/replay/, tests/wiremudder/.
- Inherited fixtures (TelnetServerStub) are reused read-only.
- No inherited source edit without a discovered-path amendment.
