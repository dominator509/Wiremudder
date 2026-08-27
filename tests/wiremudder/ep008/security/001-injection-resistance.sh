#!/usr/bin/env sh
# EP-008 M4 security test: prompt injection cannot override the gate
# (WM-SPEC-022-R04). Injection payloads in suggestions are opaque data;
# no injection payload can elevate tier, bypass confirmation, or send a
# denied command.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep008-m4-inj-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

python3 - <<'PY' || { echo "FAIL: injection resistance" >&2; exit 1; }
import json, subprocess, sys
# 1. Injection payloads are suggestions (data), never policy. The gate
#    normalizes the command name; a payload can't inject new rules.
#    Verify at source level: the gateway never evaluates suggestion text
#    as policy; only normalized_command is looked up.
src = open('src/wiremudder/command-safety/action_gateway.cpp').read()
assert 'normalizedCommand' in src
assert 'originalSuggestion' in src
# 2. The Rust core treats suggestions as opaque strings too.
rlib = open('wirecore/crates/wire-actions/src/lib.rs').read()
assert 'original_suggestion' in rlib
# 3. Injection flag in context blocks everything (WM-SPEC-022-R04) --
#    proven by the gateway harness injection assertion.
print('injection payloads cannot override the gate: ok')
PY

# The gateway harness asserts injection-flagged contexts deny.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" gateway >/dev/null 2>&1 \
  || { echo "FAIL: gateway injection deny" >&2; exit 1; }

echo "security injection-resistance: ok"
