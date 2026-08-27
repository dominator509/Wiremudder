#!/usr/bin/env sh
# EP-012 M1 contract test: inherited terminal/workspace/UI/accessibility
# surfaces exist (source evidence WM-SRC-000086..000093).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "contract: FAIL - $1" >&2; exit 1; }

for f in \
  src/TConsole.cpp src/TConsole.h \
  src/TCommandLine.cpp src/TCommandLine.h \
  src/TTextEdit.cpp src/TTextEdit.h \
  src/TBuffer.cpp src/TBuffer.h \
  src/TDockWidget.cpp src/TDockWidget.h \
  src/TMainConsole.cpp src/TMainConsole.h \
  src/TAccessibleTextEdit.cpp src/TAccessibleTextEdit.h \
  src/TAccessibleConsole.h; do
  [ -f "$f" ] || fail "inherited UI surface missing: $f"
done

# Terminal authority: raw text always visible (WM-SPEC-007-R03).
grep -q "class TConsole" src/TConsole.h || fail "TConsole missing"
# Command input surface (WM-SPEC-027-R07).
grep -q "class TCommandLine" src/TCommandLine.h || fail "TCommandLine missing"
# Text rendering pane.
grep -q "class TTextEdit" src/TTextEdit.h || fail "TTextEdit missing"
# Dockable workspace panes (WM-SPEC-007-R04).
grep -q "class TDockWidget" src/TDockWidget.h || fail "TDockWidget missing"
# Accessibility tree exposure (WM-SPEC-027-R07).
grep -q "class TAccessibleTextEdit" src/TAccessibleTextEdit.h || fail "TAccessibleTextEdit missing"
grep -q "class TAccessibleConsole" src/TAccessibleConsole.h || fail "TAccessibleConsole missing"

echo "contract EP-012 M1: ok"
