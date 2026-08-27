#!/usr/bin/env sh
# EP-015 M2 unit test: context schemas are valid JSON with stable versions.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for f in event capsule usage; do
  p="schemas/wiremudder/context/$f-v1.json"
  [ -f "$p" ] || fail "missing schema $p"
  python3 -c "import json,sys; json.load(open('$p'))" || fail "invalid JSON $p"
  grep -q '"schema_version"' "$p" || fail "schema $p missing version"
done

# The crate constants agree with the schema versions.
grep -q "CONTEXT_SCHEMA_VERSION: u32 = 1" wirecore/crates/wire-context/src/lib.rs \
  || fail "context schema version drift"
grep -q "TOKEN_BUDGET_SCHEMA_VERSION: u32 = 1" wirecore/crates/wire-token-budget/src/lib.rs \
  || fail "token budget schema version drift"

echo "unit EP-015 M2 context-schemas: ok"
