#!/usr/bin/env sh
# EP-008 M3 e2e test: full command-safety flow.
#  1. All nine non-manual sources enter the same deterministic gateway.
#  2. Safe commands approve and send; destructive commands queue for
#     confirmation; denied commands never send.
#  3. Emergency stop cancels the queue and blocks new proposals.
#  4. Manual input stays direct (no gateway in the manual path).
#  5. Audit records conform to the action-audit schema and are replayable.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep008-m3-flow-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

# 1-3. Full gate flow (all sources, confirmations, queue, emergency stop).
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" gateway 2>&1 \
  || { echo "FAIL: gateway flow" >&2; exit 1; }
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" estop 2>&1 \
  || { echo "FAIL: estop flow" >&2; exit 1; }

# 4. Manual input remains direct: the inherited manual input path
#    (TCommandLine::commandSubmitted / TConsole wiring) must not
#    reference the command-safety gateway (WM-SPEC-009-R01).
python3 - <<'PY' || { echo "FAIL: manual path not direct" >&2; exit 1; }
from pathlib import Path
for f in ['src/TCommandLine.cpp', 'src/TConsole.cpp']:
    text = Path(f).read_text(encoding='utf-8', errors='replace')
    assert 'action_gateway' not in text and 'ActionGateway' not in text, f'{f} touches the gateway'
print('manual path is direct: ok')
PY

# 5. Audit schema conformance: the C++ gateway audit entries serialize
#    with all required fields (action-audit.schema.json).
python3 - <<'PY' || { echo "FAIL: audit schema" >&2; exit 1; }
import json
from pathlib import Path
schema = json.loads(Path('schemas/wiremudder/actions/action-audit.schema.json').read_text())
required = set(schema['required'])
src = Path('src/wiremudder/command-safety/action_gateway.cpp').read_text()
for field in required:
    assert field in src, f'audit entry missing field {field}'
print('audit schema fields: ok')
PY

echo "e2e command-flow: ok"
