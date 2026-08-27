#!/usr/bin/env sh
# EP-011 M3 integration: capability states across negotiation matrix
# (ready, disabled, denied, degraded, unavailable) via real boundary exec.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep011-m3-states-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" \
  tests/wiremudder/ep011/harness/ep011_harness.cpp \
  src/wiremudder/protocol/protocol_boundary.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

# 1. READY: full negotiation set observed.
OUT=$("$HARNESS" detect "ff fb c9 ff fb 45 ff fb c8 ff fb 5b ff fb 5a ff fb 46")
grep -q "^GMCP yes negotiated$" <<EOF || { echo "FAIL: GMCP ready" >&2; echo "$OUT" >&2; exit 1; }
$OUT
EOF

# 2. DISABLED: all capabilities declined by the server.
OUT=$("$HARNESS" detect "ff fc c9 ff fe 45 ff fc c8 ff fe 5b ff fe 5a ff fe 46")
for p in GMCP MSDP ATCP MXP MSP MSSP; do
  grep -q "^$p no declined$" <<EOF || { echo "FAIL: $p declined" >&2; echo "$OUT" >&2; exit 1; }
$OUT
EOF
done

# 3. DENIED: mixed WILL/WONT — negotiated protocols stay ready, refused
#    protocols are marked declined, never silently reported ready.
OUT=$("$HARNESS" detect "ff fb c9 ff fc 45")
grep -q "^GMCP yes negotiated$" <<EOF || { echo "FAIL: GMCP ready in mixed" >&2; echo "$OUT" >&2; exit 1; }
$OUT
EOF
grep -q "^MSDP no declined$" <<EOF || { echo "FAIL: MSDP declined in mixed" >&2; echo "$OUT" >&2; exit 1; }
$OUT
EOF

# 4. DEGRADED: malformed (unterminated SB) stream still yields bounded events.
OUT=$("$HARNESS" parse "ff fa c9 41 41 41")
echo "$OUT" | grep -q "SB GMCP" || { echo "FAIL: degraded SB parse" >&2; echo "$OUT" >&2; exit 1; }

# 5. UNAVAILABLE: empty stream = all absent, no crash.
OUT=$("$HARNESS" detect "")
echo "$OUT" | grep -q "^GMCP no absent$" || { echo "FAIL: empty detect" >&2; echo "$OUT" >&2; exit 1; }

echo "integration capability-states: ok"
