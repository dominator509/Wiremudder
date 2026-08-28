#!/usr/bin/env sh
# EP-018 M2 unit test: no new external supply chain in either crate.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for crate in wire-soul wire-agents; do
  bad=$(sed -n '/^\[dependencies\]/,/^\[/p' "wirecore/crates/$crate/Cargo.toml" \
    | grep -E '^[a-z][a-z0-9_-]+ *= *"' \
    | grep -v '^serde' || true)
  [ -z "$bad" ] || fail "unexpected external dependencies in $crate: $bad"
done

echo "unit EP-018 M2 no-new-supply-chain: ok"
