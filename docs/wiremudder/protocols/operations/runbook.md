# Protocol Layer Operations (EP-011 M4)

## Health

- Boundary unit: `sh tests/wiremudder/ep011/unit/001-protocol-boundary.sh`
- Museum oracle: `sh tests/wiremudder/ep011/unit/002-protocol-museum.sh`
- Integration: `sh tests/wiremudder/ep011/integration/001-boundary-net.sh`
- Live socket: `sh tests/wiremudder/ep011/e2e/001-protocol-connect-flow.sh`

## Readiness

The protocol layer is ready when the unit tests, museum oracle, and
integration suite are green and `tests/wiremudder/ep011/e2e/*.sh` pass
against the controlled telnet fixture.

## Disable

The protocol boundary is additive and optional. Removing
`src/wiremudder/protocol/`, `compatibility/protocols/`,
`tools/protocol-museum/`, and `schemas/wiremudder/protocol/` disables it.
Manual text gameplay never depends on it (proven by
`tests/wiremudder/ep011/e2e/002-degraded-manual-flow.sh`).

## Recovery

- Malformed stream: the parser is bounded (4096-byte SB cap) and always
  makes forward progress; no recovery action needed.
- Negotiation flip: last verb wins (WONT after WILL = declined). Re-run
  the boundary or reconnect to renegotiate.
- Fixture unavailable: tests fail loudly; restart the fixture process.

## Backup and Restore

All protocol artifacts are version-controlled. Restore from git.

## Upgrade

Adding a protocol requires: option constant in
`src/wiremudder/protocol/protocol_boundary.h`, IANA option byte, museum
fixture, oracle expected entry, and unit/integration coverage together
(lockstep).

## Rollback

Revert the EP-011 commits (`git revert 1c10f6c5..HEAD`) or checkout the
lease base `0005a1b0a74ddd3941565e4b078c1565fb2f8521`. No inherited
Mudlet file is modified; rollback is clean.

## Measured Baseline (2026-08-27)

See `.agent/state/evidence/EP-011/M4/capability-latency.json`:
1.508 us per 40-byte negotiation burst (parseIac + detectCapabilities,
in-process, O2). Budget: 10 ms. Headroom ~6600x.
