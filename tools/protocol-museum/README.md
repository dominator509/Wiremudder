# Protocol Museum (tools/protocol-museum)

Raw negotiation byte streams used by EP-011 fixtures and the oracle.
Each fixture is a hex-encoded Telnet IAC stream plus the expected
capability report. No credentials, no private data.

## Fixture Format

JSON: { "fixture_id": str, "stream_hex": str, "expected": [Capability, ...] }

## Fixtures

- `gmcp-negotiation.json` - GMCP WILL/DO handshake
- `msdp-negotiation.json` - MSDP WILL/DO handshake
- `mxp-msp-mssp.json` - MXP + MSP + MSSP options
- `malformed-sb.json` - runaway subnegotiation (bounding check)
- `mixed-atcp.json` - ATCP + GMCP mixed stream
