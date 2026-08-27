#!/usr/bin/env sh
# Contract test: core inherited source symbols must exist.
set -eu
for pair in "src/mudlet.h:class mudlet" "src/Host.h:class Host" "src/ctelnet.h:class cTelnet" "src/TConsole.h:class TConsole" "src/TLuaInterpreter.h:class TLuaInterpreter"; do
  f=${pair%%:*}; sym=${pair##*:}
  grep -q "$sym" "$f" || { echo "FAIL: $sym not found in $f" >&2; exit 1; }
done
echo "contract core-symbols: ok"
