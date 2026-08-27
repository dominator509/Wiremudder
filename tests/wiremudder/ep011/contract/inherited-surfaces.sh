#!/usr/bin/env sh
# EP-011 M1 contract test: inherited protocol surfaces exist
# (source evidence WM-SRC-000082..000087).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

for f in \
  src/ctelnet.cpp src/ctelnet.h \
  src/TBuffer.cpp src/TBuffer.h \
  src/TMxpProcessor.h; do
  [ -f "$f" ] || fail "inherited protocol surface missing: $f"
done

# Key protocol symbols
grep -q "IAC\|negotiat" src/ctelnet.cpp || fail "telnet negotiation missing"
grep -q "class cTelnet" src/ctelnet.h || fail "cTelnet missing"
grep -q "class TMxpProcessor" src/TMxpProcessor.h || fail "TMxpProcessor missing"

echo "contract EP-011 M1: ok"
