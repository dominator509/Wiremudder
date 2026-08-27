# WireMudder Bridge Design — Native Bridge, WireCore Boundary, Supervision

Status: implemented and evidenced at EP-005 M3 (integration + E2E proven).
Owns: WM-FEAT-0155, WM-FEAT-0156, WM-FEAT-0157, WM-FEAT-0158.
Specifications: SPEC-002, SPEC-003, SPEC-004, SPEC-024, SPEC-025, SPEC-026.

## 1. Architecture

WireMudder keeps the pinned Mudlet-derived client as the manual gameplay
surface and adds an isolated WireCore process for optional P2-P4 work.
The two communicate over a local Unix domain socket with versioned,
newline-delimited JSON frames (see `ipc-protocol.md`).

```
┌──────────────────────────┐        Unix socket        ┌──────────────────────────┐
│ Qt client (Mudlet-based) │ ◄───────────────────────► │ Rust WireCore sidecar    │
│  WireCoreSupervisor      │   WMC1/v1 JSON frames     │  wirecore-runtime        │
│  (src/wiremudder/bridge/)│                           │  (wirecore/crates/...)   │
└──────────────────────────┘                           └──────────────────────────┘
```

Crash isolation: the sidecar is a separate process. A SIGKILL, hang, or
absence of WireCore never blocks or terminates the Qt client; the
supervisor observes the failure and restarts the sidecar with a fresh
handshake, while P0 manual text gameplay continues untouched.

## 2. Components

- `src/wiremudder/bridge/wirecore_bridge.h` / `.cpp` — Qt-side supervisor.
  Fully asynchronous (no blocking on the caller thread for optional
  work): launches the sidecar with `QProcess`, connects with
  `QLocalSocket`, performs the hello handshake, pings on a 2 s timer,
  restarts on disconnect, and shuts down cleanly.
- `wirecore/crates/wire-contracts/` — versioned frame protocol
  (magic `WMC1`, version `1`, 1 MiB bound, typed errors).
- `wirecore/crates/wirecore-runtime/` — the sidecar binary. Per-client
  thread, bounded 256-capacity event queue that drops oldest P2-P4
  frames on overflow (no P0 backpressure), snapshot, cancel, shutdown.
- `schemas/wiremudder/bridge/frame.schema.json` — machine-readable
  frame contract.

## 3. Supervision lifecycle

1. `start(binary)`: launch sidecar; connect; retry connect every 50 ms
   while the sidecar is still binding its listener (observed race:
   `waitForStarted` returns before `UnixListener::bind`).
2. Hello handshake: client sends `hello`; sidecar replies `hello_ack`
   with status/pid/queue_capacity. Until this completes, the bridge is
   "connecting" and `postRequest` frames are buffered in a bounded
   queue (256; oldest dropped on overflow).
3. Health: every 2 s the supervisor sends `ping`; a `pong` refreshes
   `m_lastPongMs`. `healthy()` is false when the peer is stale for more
   than 6 s or the process is not running.
4. Crash: socket `disconnected` fires `crashCallback` and schedules a
   restart (200 ms delay). `restartNow()` terminates any stale process,
   relaunches the sidecar, reconnects, and re-handshakes.
5. Absent: a binary path that does not exist fails `waitForStarted`;
   `readyCallback(false, ...)` reports the disabled state and
   `postRequest` returns false. Manual gameplay is unaffected.
6. Stop: `stop()` sends `shutdown`, waits at most 1.5 s for the process
   to exit, then kills it.

## 4. Exact commands

```sh
# Build the sidecar (idempotent; binary lands at wirecore/target/release/)
CARGO_TARGET_DIR="$PWD/wirecore/target" cargo build --release \
  --manifest-path wirecore/crates/wirecore-runtime/Cargo.toml

# Compile the M3 harness against the real bridge implementation
export PKG_CONFIG_PATH=/opt/qt/6.8.2/gcc_64/lib/pkgconfig
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" tests/wiremudder/ep005/harness/wirecore_bridge_harness.cpp \
  src/wiremudder/bridge/wirecore_bridge.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,/opt/qt/6.8.2/gcc_64/lib \
  -o /tmp/wm-harness

# Run the M3 integration and E2E proofs (each prints its sentinel)
sh tests/wiremudder/ep005/integration/001-bridge-lifecycle.sh
sh tests/wiremudder/ep005/integration/002-bridge-crash-restart.sh
sh tests/wiremudder/ep005/e2e/001-optional-failure-preserves-gameplay.sh
```

## 5. Observed behavior (M3 evidence)

- `integration bridge-lifecycle: ok` — hello handshake; request→response
  (`accepted:true`); snapshot (`queue_len` present); cancel
  (`cancelled:true`); healthy after real ping/pong cycle; sidecar
  process exited after clean shutdown.
- `integration bridge-crash-restart: ok` — real SIGKILL to the sidecar
  mid-session; supervisor observed the crash, relaunched the process,
  completed a fresh handshake, and became healthy again.
- `e2e optional-failure-preserves-gameplay: ok` — a 100 ms P0 gameplay
  loop never stalled (max gap < 400 ms) across: WireCore absent
  (disabled state, requests refused), WireCore up (work flows), and
  WireCore SIGKILLed mid-session (supervisor restart, work flows again).
- Sidecar direct protocol check (python): all frame kinds reply with the
  request's `frame_id`; reply kinds differ by request
  (`response` for request/cancel/shutdown, `snapshot` for snapshot,
  `pong` for ping, `hello_ack` for hello).

## 6. Data scope, privacy, and audit

- Transport is a local Unix domain socket. No remote egress, no network
  listener, no secrets in frames. Frames carry only the payload the
  caller posts; the bridge never logs payload content.
- The bridge owns no gameplay path and grants no new authority: it can
  start/stop only the sidecar binary path given to `start()`.
- Logs and evidence are redacted; no API keys or credentials are
  involved at this boundary.

## 7. Performance

- `postRequest` never blocks: writes are fire-and-forget; while
  connecting, frames buffer in a bounded 256-entry queue that drops the
  oldest P2-P4 frame on overflow, mirroring the sidecar's bounded-queue
  semantics. P0 backpressure is impossible by construction.

## 8. Rollback

- Milestone commits are individually revertible: `git revert` of the
  EP-005 M3 commit removes the bridge implementation, harness, and
  design docs while leaving the sidecar (M2) and earlier nodes intact.
- To disable WireCore entirely (fallback), simply never call
  `WireCoreSupervisor::start()`; the client runs with the bridge absent
  and `postRequest` returns false. No gameplay path references the
  bridge.

## 9. Not certified here

External adapters or platforms are not certified until M5 live-fire.
M3 proves the real local bridge/sidecar boundary only.
