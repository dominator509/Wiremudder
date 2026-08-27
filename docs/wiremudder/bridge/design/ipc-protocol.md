# WireMudder Bridge IPC Protocol

Contract: `schemas/wiremudder/bridge/frame.schema.json`
Specifications: SPEC-024 (bridge IPC API and headless contracts), SPEC-025 (errors).

## 1. Transport

- Local Unix domain socket.
- Encoding: newline-delimited JSON. One frame per line.
- Magic: `WMC1`; version: `1`. Both are validated on every frame; a
  frame with the wrong magic or version is dropped (or rejected with a
  typed error by `wire_contracts::Frame::validate`).

## 2. Frame shape

```json
{
  "magic": "WMC1",
  "version": 1,
  "frame_id": "string, >= 8 chars",
  "kind": "hello|hello_ack|ping|pong|snapshot|request|response|event|cancel|shutdown",
  "payload": { "...": "..." },
  "deadline_ms": 0
}
```

`frame_id` must be at least 8 characters. The sidecar echoes the
request's `frame_id` in its reply, which lets a client correlate
responses.

## 3. Frame kinds

| Kind        | Direction     | Meaning                                        |
| ---         | ---           | ---                                            |
| hello       | client→sidecar| Begin handshake; payload has client + pid      |
| hello_ack   | sidecar→client| Status ok, version, pid, queue_capacity        |
| ping        | client→sidecar| Health probe                                   |
| pong        | sidecar→client| Health reply (t, dropped)                      |
| snapshot    | client→sidecar| Request queue snapshot (queue_len, dropped)    |
| request     | client→sidecar| Enqueue P2-P4 work; reply accepted + depth     |
| response    | both          | Generic reply (accepted/cancelled/status)      |
| event       | either        | Asynchronous event (reserved)                  |
| cancel      | client→sidecar| Discard queued work; reply cancelled:true      |
| shutdown    | client→sidecar| Clean shutdown; sidecar exits                  |

## 4. Error behavior (SPEC-025)

- Malformed JSON or invalid magic/version: sidecar replies
  `{"status":"error","detail":"..."}` with kind `response` and
  continues.
- Oversized frame (> 1 MiB): rejected by `wire_contracts`.
- Peer gone / timeout: typed `BridgeError::PeerGone` / `Timeout` on the
  client side; the supervisor schedules a restart.

## 5. Bounded queue

The sidecar keeps a per-connection queue of capacity 256. On overflow
the oldest frame is dropped and `dropped` is incremented. P2-P4 work
degrades; P0 manual gameplay is never on this queue.

## 6. Exact commands

```sh
# Run the sidecar directly on a custom socket
wirecore/target/release/wirecore-runtime /tmp/wiremudder-wirecore.sock

# Probe it with python (handshake, snapshot, cancel, request, ping)
python3 - /tmp/wiremudder-wirecore.sock <<'PY'
import json, socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sys.argv[1]); s.settimeout(3)
def send(fid, kind, payload):
    s.sendall((json.dumps({"magic":"WMC1","version":1,"frame_id":fid,"kind":kind,"payload":payload})+"\n").encode())
def readf():
    buf = b''
    while b'\n' not in buf: buf += s.recv(65536)
    line, _ = buf.split(b'\n', 1)
    return json.loads(line)
send("dbg-0001","hello",{"client":"dbg","pid":1}); print(readf())
send("snap-0001","snapshot",{}); print(readf())
send("canc-0001","cancel",{}); print(readf())
send("req-00001","request",{"op":"echo"}); print(readf())
send("ping-0001","ping",{}); print(readf())
PY
```

## 7. Observed replies (M3 evidence, real sidecar)

- hello → hello_ack (`status: ok`, pid, queue_capacity 256)
- snapshot → snapshot (`queue_len`, `dropped`, `uptime_ms`)
- cancel → response (`cancelled: true`, `dropped`)
- request → response (`accepted: true`, `queue_depth`, `dropped`)
- ping → pong (`t`, `dropped`)

## 8. Rollback

Revert the EP-005 M3 commit to remove the harness and docs; the
protocol implementation (M2, wire-contracts + wirecore-runtime) is
unaffected. The sidecar binary path and socket path are caller-supplied
parameters, so no global configuration change is required to stop
using the bridge.
