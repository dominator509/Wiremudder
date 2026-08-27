//! WireCore bridge contracts (SPEC-024).
//!
//! Versioned local IPC frames between the Qt client and the Rust
//! WireCore sidecar. Transport is a local Unix domain socket; encoding
//! is newline-delimited JSON with a magic prefix and version const.

use serde::{Deserialize, Serialize};

pub const MAGIC: &str = "WMC1";
pub const VERSION: u32 = 1;
pub const MAX_FRAME_BYTES: usize = 1 << 20; // 1 MiB

/// Kinds of frames exchanged on the bridge.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FrameKind {
    Hello,
    HelloAck,
    Ping,
    Pong,
    Snapshot,
    Request,
    Response,
    Event,
    Cancel,
    Shutdown,
}

/// A single frame on the wire.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Frame {
    pub magic: String,
    pub version: u32,
    pub frame_id: String,
    pub kind: FrameKind,
    pub payload: serde_json::Value,
}

impl Frame {
    pub fn new(kind: FrameKind, frame_id: &str, payload: serde_json::Value) -> Self {
        Self {
            magic: MAGIC.to_string(),
            version: VERSION,
            frame_id: frame_id.to_string(),
            kind,
            payload,
        }
    }

    /// Validate magic/version/kind and frame size bound.
    pub fn validate(&self) -> Result<(), BridgeError> {
        if self.magic != MAGIC {
            return Err(BridgeError::Protocol("bad magic"));
        }
        if self.version != VERSION {
            return Err(BridgeError::VersionMismatch(self.version));
        }
        let size = serde_json::to_vec(self)
            .map(|v| v.len())
            .unwrap_or(usize::MAX);
        if size > MAX_FRAME_BYTES {
            return Err(BridgeError::Oversized(size));
        }
        Ok(())
    }

    pub fn to_wire(&self) -> Result<String, BridgeError> {
        self.validate()?;
        serde_json::to_string(self).map_err(|e| BridgeError::Encode(e.to_string()))
    }

    pub fn from_wire(line: &str) -> Result<Self, BridgeError> {
        if line.len() > MAX_FRAME_BYTES {
            return Err(BridgeError::Oversized(line.len()));
        }
        let frame: Frame =
            serde_json::from_str(line).map_err(|e| BridgeError::Decode(e.to_string()))?;
        frame.validate()?;
        Ok(frame)
    }
}

/// Typed bridge errors (SPEC-025).
#[derive(Debug, Clone, PartialEq)]
pub enum BridgeError {
    Protocol(&'static str),
    VersionMismatch(u32),
    Oversized(usize),
    Decode(String),
    Encode(String),
    PeerGone,
    Timeout,
    Cancelled,
}

impl std::fmt::Display for BridgeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BridgeError::Protocol(m) => write!(f, "protocol: {m}"),
            BridgeError::VersionMismatch(v) => write!(f, "version mismatch: {v}"),
            BridgeError::Oversized(n) => write!(f, "oversized frame: {n}"),
            BridgeError::Decode(m) => write!(f, "decode: {m}"),
            BridgeError::Encode(m) => write!(f, "encode: {m}"),
            BridgeError::PeerGone => write!(f, "peer gone"),
            BridgeError::Timeout => write!(f, "timeout"),
            BridgeError::Cancelled => write!(f, "cancelled"),
        }
    }
}

impl std::error::Error for BridgeError {}

#[cfg(test)]
mod tests {
    use super::*;

    fn frame() -> Frame {
        Frame::new(
            FrameKind::Hello,
            "frame-0001",
            serde_json::json!({"client": "wiremudder", "pid": 1}),
        )
    }

    #[test]
    fn round_trip_wire() {
        let f = frame();
        let wire = f.to_wire().unwrap();
        let back = Frame::from_wire(&wire).unwrap();
        assert_eq!(f, back);
    }

    #[test]
    fn rejects_bad_magic() {
        let mut f = frame();
        f.magic = "XXX".into();
        assert!(f.validate().is_err());
    }

    #[test]
    fn rejects_version_mismatch() {
        let mut f = frame();
        f.version = 99;
        assert!(matches!(f.validate(), Err(BridgeError::VersionMismatch(99))));
    }

    #[test]
    fn rejects_oversized() {
        let f = Frame {
            magic: MAGIC.into(),
            version: VERSION,
            frame_id: "x".repeat(MAX_FRAME_BYTES + 10),
            kind: FrameKind::Hello,
            payload: serde_json::Value::Null,
        };
        assert!(matches!(f.validate(), Err(BridgeError::Oversized(_))));
    }
}
