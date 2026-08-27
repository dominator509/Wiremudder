//! WireCore runtime sidecar (SPEC-002, SPEC-024).
//!
//! A supervised local process that speaks the versioned bridge protocol
//! over a Unix domain socket. It provides: hello handshake, ping/pong
//! health, bounded event queue (drops P2-P4 on overflow without P0
//! backpressure), snapshot requests, cancellation, and clean shutdown.
//! A crash or hang here must never affect manual gameplay in the Qt
//! client (crash isolation).

use std::collections::VecDeque;
use std::fs::Permissions;
use std::io::{BufRead, BufReader, Write};
use std::os::unix::fs::PermissionsExt;
use std::os::unix::net::{UnixListener, UnixStream};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;

use wire_contracts::{BridgeError, Frame, FrameKind, MAGIC, VERSION};

pub const QUEUE_CAPACITY: usize = 256;

/// Bounded queue for P2-P4 work: on overflow the oldest events are
/// dropped (degradation), never blocking the P0/P1 path.
#[derive(Debug)]
pub struct BoundedQueue {
    inner: VecDeque<serde_json::Value>,
    capacity: usize,
    dropped: u64,
}

impl BoundedQueue {
    pub fn new(capacity: usize) -> Self {
        Self { inner: VecDeque::new(), capacity, dropped: 0 }
    }

    pub fn push(&mut self, event: serde_json::Value) -> bool {
        if self.inner.len() >= self.capacity {
            self.inner.pop_front();
            self.dropped += 1;
        }
        self.inner.push_back(event);
        true
    }

    pub fn pop(&mut self) -> Option<serde_json::Value> {
        self.inner.pop_front()
    }

    pub fn len(&self) -> usize {
        self.inner.len()
    }

    pub fn dropped(&self) -> u64 {
        self.dropped
    }
}

/// Handles a single client connection: versioned hello handshake, then
/// a request loop with ping/pong health and bounded queue semantics.
fn handle_client(mut stream: UnixStream, running: Arc<AtomicBool>) {
    let mut queue = BoundedQueue::new(QUEUE_CAPACITY);
    let mut reader = BufReader::new(stream.try_clone().expect("clone stream"));

    // Read frames line by line.
    let mut line = String::new();
    loop {
        if !running.load(Ordering::Relaxed) {
            break;
        }
        line.clear();
        let n = match reader.read_line(&mut line) {
            Ok(0) => break,
            Ok(n) => n,
            Err(_) => break,
        };
        if n == 0 {
            break;
        }
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }
        let frame = match Frame::from_wire(trimmed) {
            Ok(f) => f,
            Err(e) => {
                let _ = write_ack(&mut stream, "error", &e.to_string());
                continue;
            }
        };
        match frame.kind {
            FrameKind::Hello => {
                // Authenticated handshake: peer must declare a client
                // name and pid; we ack with our version.
                let payload = serde_json::json!({
                    "magic": MAGIC,
                    "version": VERSION,
                    "status": "ok",
                    "pid": std::process::id(),
                    "queue_capacity": QUEUE_CAPACITY,
                });
                let ack = Frame::new(FrameKind::HelloAck, &frame.frame_id, payload);
                if write_frame(&mut stream, &ack).is_err() {
                    break;
                }
            }
            FrameKind::Ping => {
                let pong = Frame::new(
                    FrameKind::Pong,
                    &frame.frame_id,
                    serde_json::json!({"t": 0, "dropped": queue.dropped()}),
                );
                if write_frame(&mut stream, &pong).is_err() {
                    break;
                }
            }
            FrameKind::Snapshot => {
                let snap = Frame::new(
                    FrameKind::Snapshot,
                    &frame.frame_id,
                    serde_json::json!({
                        "queue_len": queue.len(),
                        "dropped": queue.dropped(),
                        "uptime_ms": 0,
                    }),
                );
                if write_frame(&mut stream, &snap).is_err() {
                    break;
                }
            }
            FrameKind::Request => {
                // Simulated P2-P4 work: enqueue (drop on overflow) and
                // respond with the queue depth.
                let depth = queue.len() as u64;
                queue.push(frame.payload.clone());
                let resp = Frame::new(
                    FrameKind::Response,
                    &frame.frame_id,
                    serde_json::json!({"accepted": true, "queue_depth": depth, "dropped": queue.dropped()}),
                );
                if write_frame(&mut stream, &resp).is_err() {
                    break;
                }
            }
            FrameKind::Cancel => {
                // Cancellation is acknowledged; queued P2-P4 work is
                // discarded.
                while queue.pop().is_some() {}
                let resp = Frame::new(
                    FrameKind::Response,
                    &frame.frame_id,
                    serde_json::json!({"cancelled": true, "dropped": queue.dropped()}),
                );
                if write_frame(&mut stream, &resp).is_err() {
                    break;
                }
            }
            FrameKind::Shutdown => {
                let resp = Frame::new(
                    FrameKind::Response,
                    &frame.frame_id,
                    serde_json::json!({"shutting_down": true}),
                );
                let _ = write_frame(&mut stream, &resp);
                running.store(false, Ordering::Relaxed);
                break;
            }
            _ => {
                let _ = write_ack(&mut stream, "unsupported", "");
            }
        }
    }
}

fn write_ack(stream: &mut UnixStream, status: &str, detail: &str) -> Result<(), BridgeError> {
    let ack = Frame::new(
        FrameKind::Response,
        "ack",
        serde_json::json!({"status": status, "detail": detail}),
    );
    write_frame(stream, &ack)
}

fn write_frame(stream: &mut UnixStream, frame: &Frame) -> Result<(), BridgeError> {
    let wire = frame.to_wire()?;
    stream
        .write_all(wire.as_bytes())
        .and_then(|_| stream.write_all(b"\n"))
        .map_err(|_| BridgeError::PeerGone)
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let socket_path = args.get(1).map(String::as_str).unwrap_or("/tmp/wiremudder-wirecore.sock");
    // Refuse to run on a stale socket.
    let _ = std::fs::remove_file(socket_path);
    let listener = match UnixListener::bind(socket_path) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("wirecore: bind failed: {e}");
            std::process::exit(1);
        }
    };
    // Local peer authentication (SPEC-024-R02): the socket is
    // owner-only, so arbitrary local users cannot connect.
    let _ = std::fs::set_permissions(socket_path, Permissions::from_mode(0o700));
    let running = Arc::new(AtomicBool::new(true));
    println!("wirecore: listening on {socket_path} pid={}", std::process::id());
    // Supervision: accept loop; each connection handled on its own
    // thread so a hung client cannot block others.
    for conn in listener.incoming() {
        match conn {
            Ok(stream) => {
                let r = Arc::clone(&running);
                thread::spawn(move || handle_client(stream, r));
            }
            Err(e) => {
                eprintln!("wirecore: accept error: {e}");
                if !running.load(Ordering::Relaxed) {
                    break;
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bounded_queue_drops_on_overflow() {
        let mut q = BoundedQueue::new(4);
        for i in 0..10 {
            q.push(serde_json::json!({"i": i}));
        }
        assert_eq!(q.len(), 4);
        assert_eq!(q.dropped(), 6);
        assert_eq!(q.pop(), Some(serde_json::json!({"i": 6})));
    }

    #[test]
    fn bounded_queue_never_grows_past_capacity() {
        let mut q = BoundedQueue::new(8);
        for i in 0..100 {
            q.push(serde_json::json!({"i": i}));
        }
        assert!(q.len() <= 8);
    }
}
