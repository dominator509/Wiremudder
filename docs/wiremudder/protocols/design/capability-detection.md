# WireMudder Protocol Capability Detection — Design

Node EP-011, milestone M3. Integrates the Telnet IAC protocol boundary
(`src/wiremudder/protocol/protocol_boundary.{h,cpp}`) with the Qt runtime
and proves optional-protocol failure preserves manual text gameplay.

## Architecture

- `src/wiremudder/protocol/protocol_boundary.{h,cpp}` — real Telnet IAC
  parser (WILL/WONT/DO/DONT/SB, escaped-IAC, 4096-byte SB bound) and
  capability detector over the negotiation matrix (GMCP/MSDP/MXP/MSP/ATCP/
  MSSP + research-status MCP/Pueblo/GSL).
- `compatibility/protocols/protocol_oracle.py` — expected-entry oracle for
  the museum fixtures.
- `tools/protocol-museum/*.json` — 5 negotiation fixtures.
- `schemas/wiremudder/protocol/capability.schema.json` — capability record
  schema.
- Harness `tests/wiremudder/ep011/harness/ep011_harness.cpp` — compiles the
  boundary against Qt 6.8.2 and drives it over real `QTcpSocket` connects.
- Fixture `tests/wiremudder/ep011/fixtures/telnet_server.py` — controlled
  local telnet server (SIMULATION) with negotiate/decline/garbage modes.

## Capability states

| State        | Meaning                                        |
|--------------|------------------------------------------------|
| negotiated   | observed WILL/DO for the option                |
| declined     | observed WONT/DONT for the option              |
| absent       | no negotiation bytes observed                  |
| research     | no inherited option byte; declared, not wired  |

## Exact commands

```sh
# Boundary unit + museum oracle (M2)
sh tests/wiremudder/ep011/unit/001-protocol-boundary.sh
sh tests/wiremudder/ep011/unit/002-protocol-museum.sh

# Integration (real boundary exec)
sh tests/wiremudder/ep011/integration/001-boundary-net.sh
sh tests/wiremudder/ep011/integration/002-capability-states.sh

# E2E (real socket connects to controlled fixture)
sh tests/wiremudder/ep011/e2e/001-protocol-connect-flow.sh
sh tests/wiremudder/ep011/e2e/002-degraded-manual-flow.sh

# Node gate
sh scripts/node-verifiers/EP-011.sh M3
```

## Observed behavior

- WILL GMCP (`ff fb c9`) / WILL MSDP (`ff fb 45`) / WILL ATCP (`ff fb c8`)
  parse to their named options; detect reports `negotiated`.
- WONT/DONT report `declined`; empty stream reports `absent`; MCP/Pueblo/
  GSL report `research`.
- Escaped IAC (`ff ff`) inside SB does not terminate the subnegotiation.
- Unterminated SB is bounded at 4096 bytes; the parser returns, never hangs.
- Over a real socket, manual text round-trips (`echo:hello manual gameplay`)
  while negotiation is active, and after garbage or declined negotiation.

## Rollback

The protocol boundary is additive: no inherited Mudlet file is modified.
Rollback = revert the EP-011 commits (`git revert 1c10f6c5..HEAD` for M2/M3)
or checkout the lease base `0005a1b0a74ddd3941565e4b078c1565fb2f8521`.
The inherited negotiation path (ctelnet / TMxpProcessor) remains untouched.
