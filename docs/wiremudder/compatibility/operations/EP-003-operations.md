# WireMudder Compatibility Oracle Operations — EP-003

## Health

- `python3 compatibility/replay/replay_validate.py <file.json>` prints
  `replay validate: ok`.
- Museum servers bind 127.0.0.1 only; scenarios list via
  `python3 compatibility/protocol-museum/museum.py` (prints a scenario).

## Readiness

The oracle is ready when: `schemas/wiremudder/replay/session-replay.schema.json`
exists, museum scenarios are importable, and
`tests/wiremudder/ep003/unit/004-oracle-record.sh` passes.

## Capture a Session

```sh
python3 tools/protocol-museum/oracle_record.py text-stream /tmp/replay.json
python3 compatibility/replay/replay_validate.py /tmp/replay.json
```

## Recovery and Restart

- A stuck capture: the recorder is bounded (2s socket timeout, 0.5s
  duration); kill and retry.
- Museum port conflict: FakeMudServer binds port 0 (ephemeral) by
  default; fixed-port probes use 42421 only in tests.

## Backup and Restore

- Fixtures are derived artifacts; regenerate with oracle_record.py.
- Schema and tooling are in-git under schemas/wiremudder/replay/,
  compatibility/, tools/protocol-museum/.

## Upgrade and Rollback

- Replay schema changes require a schema_version bump and spec-update
  process; rollback = git revert.

## Incident Response

- Secret leaked into a fixture: run `security/001-fixture-scan.sh`,
  remove the secret, re-record sanitized.
- Museum server exposed externally: verify loopback binding with
  `security/002-loopback-only.sh`; change the bind address.
