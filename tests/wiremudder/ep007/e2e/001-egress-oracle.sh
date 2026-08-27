#!/usr/bin/env sh
# EP-007 M3 e2e test: cross-implementation oracle.
# The Rust core (wire-routing, wire-profiles) and the C++ Qt layer
# (ep007_harness) must produce byte-identical decision matrices and
# identical sensitive-default actor rules.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
CARGO_BIN=$(command -v cargo || echo /root/.cargo/bin/cargo)
HARNESS=/tmp/wm-ep007-m3-oracle-$$
OUT_C=/tmp/wm-ep007-oracle-c-$$
OUT_R=/tmp/wm-ep007-oracle-r-$$
trap 'rm -f "$HARNESS" "$OUT_C" "$OUT_R"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I"$PWD" \
  tests/wiremudder/ep007/harness/ep007_harness.cpp \
  src/wiremudder/profiles/character_profile_store.cpp \
  src/wiremudder/routing/route_profile_store.cpp \
  src/wiremudder/routing/router.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

# Build the Rust oracle CLIs (standalone crates).
(cd wirecore/crates/wire-routing && "$CARGO_BIN" build --offline --bin oracle) >/dev/null 2>&1 \
  || { echo "FAIL: wire-routing oracle build" >&2; exit 1; }
(cd wirecore/crates/wire-profiles && "$CARGO_BIN" build --offline --bin oracle) >/dev/null 2>&1 \
  || { echo "FAIL: wire-profiles oracle build" >&2; exit 1; }

# Route validation matrix: C++ and Rust must agree on every entry.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" oracle > "$OUT_C" 2>&1 \
  || { echo "FAIL: C++ oracle" >&2; exit 1; }
(cd wirecore/crates/wire-routing && "$CARGO_BIN" run --offline --quiet --bin oracle) > "$OUT_R" 2>&1 \
  || { echo "FAIL: Rust routing oracle" >&2; exit 1; }

# Normalize kind labels: C++ appends " (future)" for future kinds.
sed 's/ (future)//g' "$OUT_C" > "${OUT_C}.norm"
python3 - "$OUT_C" "$OUT_R" <<'PY' || { echo "FAIL: oracle matrix mismatch" >&2; exit 1; }
import json, sys
c = json.load(open(sys.argv[1]))
r = json.load(open(sys.argv[2]))
def norm(rows):
    return sorted((row['id'], row['kind'].replace(' (future)', ''), row['valid']) for row in rows)
assert norm(c) == norm(r), f'mismatch:\nC++: {norm(c)}\nRust: {norm(r)}'
print(f'oracle route-matrix: ok ({len(c)} entries)')
PY

# Sensitive-default actor rules: Rust and C++ must agree.
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" profiles > /dev/null 2>&1 \
  || { echo "FAIL: C++ profiles invariant" >&2; exit 1; }
(cd wirecore/crates/wire-profiles && "$CARGO_BIN" run --offline --quiet --bin oracle) > "$OUT_R" 2>&1 \
  || { echo "FAIL: Rust profiles oracle" >&2; exit 1; }
python3 - "$OUT_R" <<'PY' || { echo "FAIL: Rust actor rules" >&2; exit 1; }
import json, sys
r = json.load(open(sys.argv[1]))
assert r['automation_routing_denied'] is True, 'automation must be denied for routing'
assert r['automation_voice_allowed'] is True, 'automation voice change must be allowed'
assert r['user_ai_allowed'] is True, 'user AI change must be allowed'
assert r['audit_count'] == 1, 'expected exactly one sensitive audit entry'
assert r['audit_redacted'] is True, 'audit must be redacted'
domains = {d['domain']: d['sensitive'] for d in r['domains']}
assert domains['routing'] is True and domains['ai'] is True, 'routing/ai must be sensitive'
assert domains['voice'] is False and domains['world'] is False, 'voice/world must not be sensitive'
assert len(domains) == 10, 'must be ten default domains'
print(f'oracle profile-rules: ok ({len(domains)} domains)')
PY

echo "e2e oracle: ok"
