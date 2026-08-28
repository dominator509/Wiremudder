#!/usr/bin/env sh
# WM-SPEC-011-R03: structured profile, memory, map augmentation, policy,
# package, audit, telemetry, and update metadata has explicit schema
# ownership and migrations. Telemetry events own schema_version and the
# canonical event schema.
set -eu
cd "$(dirname "$0")/../../../../.."
fail() { echo "requirement wm-spec-011-r03: FAIL - $1" >&2; exit 1; }
LIB=wirecore/crates/wire-telemetry/src/lib.rs
[ -f "$LIB" ] || fail "wire-telemetry crate missing"
grep -q "TELEMETRY_SCHEMA_VERSION" "$LIB" || fail "schema version constant missing"
grep -q "schema_version" "$LIB" || fail "schema ownership missing"
grep -q '"$id"' schemas/wiremudder/telemetry/event.schema.json || fail "schema lacks canonical id"
grep -q '"schema_version"' schemas/wiremudder/telemetry/event.schema.json || fail "schema lacks version"
echo "requirement wm-spec-011-r03 schema-ownership: ok"
