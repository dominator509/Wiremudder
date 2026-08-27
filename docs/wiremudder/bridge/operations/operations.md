# WireMudder Bridge Operations

Node: EP-005 (Native Bridge, WireCore Boundary, Supervision)
Specifications: SPEC-024, SPEC-025, SPEC-026.

## Health

- `healthy()` on `WireCoreSupervisor` is true only when: the hello
  handshake completed (`m_connected`), the sidecar process is running,
  and the last `pong` is fresher than 6 s.
- The supervisor pings every 2 s (`QTimer`). A stale peer (6 s without
  pong) is treated as a hang: the supervisor emits `crashCallback` and
  restarts the sidecar.
- Readiness: the `readyCallback(ok, error)` fires once per start with
  the handshake result. Until then, requests are buffered in the
  bounded pending queue; when WireCore is absent, `postRequest`
  returns false immediately.

## Disable

- Fallback is the default: never call `start()`. The client runs
  without WireCore; `postRequest` returns false and no gameplay path
  is affected.
- To disable at runtime after a start: call `stop()`; the supervisor
  sends `shutdown`, waits at most 1.5 s, then kills the process.

## Recovery

- Crash: supervisor auto-restarts within ~200 ms (detect + relaunch +
  fresh handshake). No operator action needed.
- Hang (SIGSTOP or wedged peer): stale-pong detection restarts within
  ~6-8 s. No operator action needed.
- Absent binary: `start()` reports `ready(false, "sidecar failed to
  start")`; requests are refused (false), never queued forever.
- Stale socket: the sidecar removes the socket file at startup before
  binding, so a crashed peer's socket never blocks a restart.

## Backup / Restore

- The bridge owns no persistent state: the sidecar is a stateless
  queue holder for the current session. Backing up the client's
  existing profile data (unchanged by this node) is the only relevant
  backup. Restore = restart the client; the supervisor re-launches
  the sidecar automatically.

## Upgrade

- Sidecar binary: build with
  `CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml`.
  `start()` launches whatever binary path is supplied, so an upgrade
  is a drop-in replacement of that path.
- Protocol version: frames carry `magic: WMC1` and `version: 1`;
  a version mismatch is rejected by `wire_contracts` with a typed
  error, and the supervisor reports the failed handshake rather than
  silently degrading.

## Rollback

- Code: `git revert` of the EP-005 M4 commit (and M3 if desired)
  removes the failure/security/performance tests and ops docs while
  leaving the bridge and sidecar functional.
- Runtime: stop using the bridge by not calling `start()`; no config
  change needed.

## Bounded recovery runbook

1. Observe: `readyCallback(false, ...)` or `crashCallback` fired.
2. Diagnose: if `start()` failed, check the binary path exists and is
   executable; check the socket path is not held by another process
   (`ls -l <socket>`; mode must be 700).
3. Recover: for a missing binary, provide the built
   `wirecore/target/release/wirecore-runtime` path and call `start()`
   again. For a hang/crash, no action: the supervisor restarts.
4. Escalate only if three consecutive restarts fail: then WireCore is
   left disabled (do not call `start()`), manual gameplay continues,
   and the issue is investigated with the sidecar stderr log.
