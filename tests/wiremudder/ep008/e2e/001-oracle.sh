#!/usr/bin/env sh
# EP-008 M3 e2e test: cross-implementation oracle.
# The Rust cores (wire-policy, wire-actions) and the C++ Qt layer
# (ep008_harness) must agree on the policy matrix and gate decisions.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
CARGO_BIN=$(command -v cargo || echo /root/.cargo/bin/cargo)
HARNESS=/tmp/wm-ep008-m3-oracle-$$
OUT_C=/tmp/wm-ep008-oracle-c-$$
OUT_R=/tmp/wm-ep008-oracle-r-$$
trap 'rm -f "$HARNESS" "$OUT_C" "$OUT_R"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep008/harness/ep008_harness.cpp \
  src/wiremudder/command-safety/action_gateway.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

(cd wirecore/crates/wire-policy && "$CARGO_BIN" build --offline --bin oracle) >/dev/null 2>&1 \
  || { echo "FAIL: wire-policy oracle build" >&2; exit 1; }
(cd wirecore/crates/wire-actions && "$CARGO_BIN" build --offline --bin oracle) >/dev/null 2>&1 \
  || { echo "FAIL: wire-actions oracle build" >&2; exit 1; }

# Policy matrix: C++ and Rust must agree on tier/denied/confirmation/args.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" oracle > "$OUT_C" 2>&1 \
  || { echo "FAIL: C++ oracle" >&2; exit 1; }
(cd wirecore/crates/wire-policy && "$CARGO_BIN" run --offline --quiet --bin oracle) > "$OUT_R" 2>&1 \
  || { echo "FAIL: Rust policy oracle" >&2; exit 1; }

python3 - "$OUT_C" "$OUT_R" <<'PY' || { echo "FAIL: policy matrix mismatch" >&2; exit 1; }
import json, sys
c = json.load(open(sys.argv[1]))
r = json.load(open(sys.argv[2]))
def norm(rows):
    return sorted((row['command'], row['tier'], row['denied'], row['requires_confirmation'], row['arg_ok']) for row in rows)
assert norm(c['matrix']) == norm(r['matrix']), f'mismatch:\nC++: {norm(c["matrix"])}\nRust: {norm(r["matrix"])}'
print(f'oracle policy-matrix: ok ({len(c["matrix"])} entries)')
PY

# Gate decisions: C++ vs Rust for the comparable scenarios.
(cd wirecore/crates/wire-actions && "$CARGO_BIN" run --offline --quiet --bin oracle) > "$OUT_R" 2>&1 \
  || { echo "FAIL: Rust actions oracle" >&2; exit 1; }
python3 - "$OUT_C" "$OUT_R" <<'PY' || { echo "FAIL: gate matrix mismatch" >&2; exit 1; }
import json, sys
c = json.load(open(sys.argv[1]))
r = json.load(open(sys.argv[2]))
# Rust decisions render as e.g. "Approved", "NeedsConfirmation", "Denied(DeniedByPolicy)".
def norm_decision(d):
    return d.split('(')[0]
c_gates = {(g['source'], g['suggestion']): norm_decision(g['decision']) for g in c['gates']}
r_gates = {(g['source'], g['suggestion']): norm_decision(g['decision']) for g in r['matrix']}
for key in sorted(set(c_gates) & set(r_gates)):
    assert c_gates[key] == r_gates[key], f'gate mismatch {key}: C++={c_gates[key]} Rust={r_gates[key]}'
print(f'oracle gate-decisions: ok ({len(set(c_gates) & set(r_gates))} shared scenarios)')
PY

echo "e2e oracle: ok"
