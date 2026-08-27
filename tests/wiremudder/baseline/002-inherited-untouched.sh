#!/usr/bin/env sh
# Baseline test: inherited source core files exist and are untouched
# (hash-verified against the pinned commit).
set -eu
python3 - <<'PY' || { echo "FAIL: inherited source drift" >&2; exit 1; }
import subprocess
from pathlib import Path
base = '77086c295f4adf59197e586e689d19bdde8e1008'
for f in ['src/mudlet.cpp', 'src/Host.cpp', 'src/ctelnet.cpp', 'src/TLuaInterpreter.cpp', 'src/TConsole.cpp', 'CMakeLists.txt', 'CMakePresets.json']:
    p = Path(f)
    assert p.is_file(), f'missing {f}'
    upstream = subprocess.run(['git','show',f'{base}:{f}'], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout
    current = p.read_bytes()
    assert upstream == current, f'drift in {f}'
print('baseline inherited-untouched: ok')
PY
echo "baseline inherited-untouched: ok"
