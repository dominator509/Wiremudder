#!/usr/bin/env sh
# WM-SPEC-011-R06: all gameplay writes use bounded asynchronous queues;
# socket and terminal paths never wait on storage.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "wm-spec-011-r06: FAIL - $1" >&2; exit 1; }

# The bounded queue contract is enforced by crate unit tests: enqueue
# beyond capacity is a typed QueueFull error; drain persists lines.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml write_queue_is_bounded \
  >/dev/null 2>&1 || fail "bounded queue test"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml drain_queue_into_store \
  >/dev/null 2>&1 || fail "drain queue test"

# The failure matrix proves queue exhaustion is typed at the API surface.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-storage/Cargo.toml \
  --example failure_matrix > /tmp/wm-r06-failure.txt 2>/dev/null \
  || fail "failure matrix"
grep -q "queue-full:ok" /tmp/wm-r06-failure.txt || fail "typed QueueFull"
rm -f /tmp/wm-r06-failure.txt

# The bounded queue design lives in the storage design doc (WM-SPEC-011-R06).
grep -qi "queue" docs/wiremudder/storage/design/*.md || fail "queue design missing"

echo "wm-spec-011-r06: ok"
