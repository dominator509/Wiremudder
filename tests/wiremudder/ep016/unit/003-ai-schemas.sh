#!/usr/bin/env sh
# EP-016 M2 unit test: AI schemas are valid JSON with stable versions.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

for f in provider-capability routing-decision evaluation-report; do
  p="schemas/wiremudder/ai/$f-v1.json"
  [ -f "$p" ] || fail "missing schema $p"
  python3 -c "import json,sys; json.load(open('$p'))" || fail "invalid JSON $p"
  grep -q '"schema_version"' "$p" || fail "schema $p missing version"
done

# The crate constants agree with the schema versions.
grep -q "ADAPTER_SCHEMA_VERSION: u32 = 1" wirecore/crates/wire-provider-adapters/src/lib.rs \
  || fail "adapter schema version drift"
grep -q "ROUTER_SCHEMA_VERSION: u32 = 1" wirecore/crates/wire-ai-router/src/lib.rs \
  || fail "router schema version drift"

echo "unit EP-016 M2 ai-schemas: ok"
