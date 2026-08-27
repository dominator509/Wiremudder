#!/usr/bin/env sh
# EP-015 contract test: inherited surfaces used by this node are real and
# locked by source evidence; no inherited edit is legal without a
# discovered-path amendment row.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

# The inherited surfaces this node depends on exist in the tree.
grep -q "class TEvent" src/TEvent.h || fail "TEvent surface missing"
grep -q "raiseEvent" src/TLuaInterpreter.cpp || fail "raiseEvent surface missing"
grep -q "parseCommandOrFunction" src/TLuaInterpreter.h || fail "parse surface missing"
grep -q "class TTrigger" src/TTrigger.h || fail "TTrigger surface missing"

# Each surface is locked by a source-evidence record for EP-015.
for path in src/TEvent.h src/TLuaInterpreter.cpp src/TLuaInterpreter.h src/TTrigger.h; do
  grep -q "\"path\": \"$path\"" .agent/state/source-evidence.jsonl \
    || fail "no source evidence for $path"
done

# The discovered amendment is present and append-only shaped.
grep -q "Brownfield discovered-path amendment" .agent/expected-files/EP-015.discovered.txt \
  || fail "discovered amendment missing header"

echo "contract inherited-surfaces: ok"
