#!/usr/bin/env sh
# EP-017 M2 unit test: the copilot crate builds into the wirecore target
# without new supply chain (no external dependency beyond serde/json and
# existing wirecore crates).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

# Only allowed external crates: serde, serde_json. Everything else must be a
# wirecore path dependency. Restrict to the [dependencies] section.
bad=$(sed -n '/^\[dependencies\]/,/^\[/p' wirecore/crates/wire-copilot/Cargo.toml \
  | grep -E '^[a-z][a-z0-9_-]+ *= *"' \
  | grep -v '^serde' || true)
[ -z "$bad" ] || fail "unexpected external dependencies: $bad"

echo "unit EP-017 M2 no-new-supply-chain: ok"
