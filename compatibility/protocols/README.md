# Protocol Compatibility Matrix (compatibility/protocols)

Oracle and fixture conventions for SPEC-006 / EP-011 protocol handling.

## Purpose

WireMudder preserves the inherited Telnet engine (cTelnet, WM-SRC-000082)
and extends capability detection without touching inherited code. This
tree defines how negotiation streams are parsed, how capabilities are
reported, and which protocols are research-status.

## Protocol Matrix

| Protocol | Option | Status | Source |
|----------|--------|--------|--------|
| GMCP | 201 | negotiated (WILL/DO) | cTelnet (WM-SRC-000082) |
| MSDP | 69 | negotiated | cTelnet |
| MXP | 91 | negotiated | TMxpProcessor (WM-SRC-000087) |
| MSP | 90 | negotiated | cTelnet |
| ATCP | 200 | negotiated | cTelnet |
| MSSP | 70 | negotiated | cTelnet |
| MCP | - | research | no inherited option byte |
| Pueblo | - | research | no inherited option byte |
| Simutronics/GSL | - | research | no inherited option byte |

## Capability Report Schema

See `schemas/wiremudder/protocol/capability.schema.json`.

## Fixtures

Raw negotiation byte streams live in `tools/protocol-museum/`. Each
fixture is a hex-encoded IAC stream with an expected capability report.
Run the oracle to verify:

    python3 compatibility/protocols/protocol_oracle.py --check-all

## Security

Malformed negotiation input is bounded (SB truncation cap 4096 bytes).
No fixture contains credentials or private data.
