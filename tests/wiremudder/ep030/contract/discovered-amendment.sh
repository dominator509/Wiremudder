#!/usr/bin/env sh
# EP-030 M1 contract test: the discovered-path amendment for the inherited
# CMakeLists.txt exists and carries the required evidence header.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

[ -f .agent/expected-files/EP-030.discovered.txt ] || fail "missing discovered amendment"

# The inherited integration path is declared with evidence.
grep -q '"path":"src/CMakeLists.txt"' .agent/expected-files/EP-030.discovered.txt \
  || fail "src/CMakeLists.txt not in discovered amendment"
grep -q "WM-SRC-000221" .agent/expected-files/EP-030.discovered.txt \
  || fail "source evidence id missing from amendment"

# The static fence authorizes the discovered amendment file.
grep -q ".agent/expected-files/EP-030.discovered.txt" .agent/expected-files/EP-030.txt \
  || fail "discovered amendment not in static fence"

echo "contract EP-030 discovered-amendment: ok"
