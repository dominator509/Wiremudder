#!/usr/bin/env sh
# EP-019 M2 unit test: no new external supply chain in wire-autopilot.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

bad=$(sed -n '/^\[dependencies\]/,/^\[/p' wirecore/crates/wire-autopilot/Cargo.toml \
  | grep -E '^[a-z][a-z0-9_-]+ *= *"' \
  | grep -v '^serde' || true)
[ -z "$bad" ] || fail "unexpected external dependencies in wire-autopilot: $bad"

# The crate must build on the EP-008/EP-009 path deps, not new ones.
grep -q "wire-actions" wirecore/crates/wire-autopilot/Cargo.toml || fail "missing wire-actions path dep"
grep -q "wire-policy" wirecore/crates/wire-autopilot/Cargo.toml || fail "missing wire-policy path dep"

echo "unit EP-019 M2 no-new-supply-chain: ok"
