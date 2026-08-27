#!/usr/bin/env sh
# EP-011 M2 unit test: protocol museum fixtures agree through the oracle.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

python3 compatibility/protocols/protocol_oracle.py || fail "protocol oracle"

echo "unit EP-011 M2 museum: ok"
