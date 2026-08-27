#!/usr/bin/env sh
# EP-014 M1 contract test: inherited storage/search surfaces exist
# (source evidence WM-SRC-000101..000103) and the host provides SQLite.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# Inherited surfaces referenced by this node.
[ -f src/TLuaInterpreter.cpp ] || fail "TLuaInterpreter.cpp missing"
grep -q "luasql.sqlite3" src/TLuaInterpreter.cpp || fail "luasql.sqlite3 missing"
grep -q "searchRoom" src/TLuaInterpreter.cpp || fail "searchRoom missing"
grep -q "getRoomHidden" src/TLuaInterpreter.cpp || fail "getRoomHidden missing"

# Host SQLite available for the wire-storage crate and backup tool.
sqlite3 --version >/dev/null 2>&1 || python3 -c "import sqlite3" 2>/dev/null \
  || fail "no sqlite3 available on host"

# Versioned schema requirement (WM-SPEC-023-R08): storage schemas dir is
# a fence-authorized boundary.
grep -q "schemas/wiremudder/storage/" .agent/expected-files/EP-014.txt \
  || fail "storage schema boundary missing from fence"

echo "contract EP-014 M1: ok"
