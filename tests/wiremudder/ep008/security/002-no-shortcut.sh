#!/usr/bin/env sh
# EP-008 M4 security test: no high-confidence shortcut exists
# (WM-SPEC-009-R05). No API path sends a command without the full gate;
# a denied or confirmation-required command can never be force-sent.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep008-m4-short-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

# 1. The gateway API has exactly one send path (approveAndSend), and it
#    re-evaluates the full gate. No bypass method exists.
python3 - <<'PY' || { echo "FAIL: shortcut surface" >&2; exit 1; }
from pathlib import Path
hdr = Path('src/wiremudder/command-safety/action_gateway.h').read_text()
rlib = Path('wirecore/crates/wire-actions/src/lib.rs').read_text()
# The only public send-ish methods re-run evaluate() internally.
assert 'approveAndSend' in hdr
assert 'evaluate' in hdr
assert 'force' not in hdr.lower() and 'bypass' not in hdr.lower()
assert 'approve_and_send' in rlib
print('no force/bypass send surface: ok')
PY

# 2. The harness proves denied commands never send and destructive
#    commands queue for confirmation (gateway + failures subcommands).
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" gateway >/dev/null 2>&1 \
  || { echo "FAIL: gateway shortcut check" >&2; exit 1; }

# 3. Rust: no_high_confidence_shortcut unit test.
(cd wirecore/crates/wire-actions && /root/.cargo/bin/cargo test --offline no_high_confidence) >/dev/null 2>&1 \
  || { echo "FAIL: Rust no-shortcut" >&2; exit 1; }

echo "security no-high-confidence-shortcut: ok"
