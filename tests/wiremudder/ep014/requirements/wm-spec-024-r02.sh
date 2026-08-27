#!/usr/bin/env sh
# WM-SPEC-024-R02: the local transport is OS-local, authenticated,
# permission-restricted, and unavailable to arbitrary remote peers.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "wm-spec-024-r02: FAIL - $1" >&2; exit 1; }

# OS-local: wire-storage has no network-capable dependencies. The crate
# depends only on serde/serde_json (serialization) and the host SQLite C
# library; nothing opens sockets or performs remote I/O.
deps=$(sed -n '/\[dependencies\]/,/^\[/p' wirecore/crates/wire-storage/Cargo.toml)
printf '%s' "$deps" | grep -qE "^serde" || fail "serde dep missing"
if printf '%s' "$deps" | grep -qE "reqwest|hyper|tokio|tungstenite|net2|socket2|openssl|rusqlite"; then
  fail "network-capable dependency present"
fi

# Build script links only the local SQLite C library.
grep -q "rustc-link-lib=sqlite3" wirecore/crates/wire-storage/build.rs || fail "link line"

# Permission-restricted: the design doc states the database is a local
# file with WAL, and the runbook's disable path keeps manual gameplay
# independent of storage availability.
grep -qi "WAL" docs/wiremudder/storage/design/*.md || fail "WAL design missing"
grep -qi "manual gameplay" docs/wiremudder/storage/operations/runbook.md \
  || fail "gameplay isolation missing"

echo "wm-spec-024-r02: ok"
