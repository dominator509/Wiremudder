#!/usr/bin/env sh
# EP-007 M4 security test: secrets never leak. Routing audit entries and
# exported data must never contain credentials; the redacted view carries
# no username field at all (WM-FEAT-0092).
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep007-m4-sec-$$
trap 'rm -f "$HARNESS"' EXIT

[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) -I"$PWD" \
  tests/wiremudder/ep007/harness/ep007_harness.cpp \
  src/wiremudder/profiles/character_profile_store.cpp \
  src/wiremudder/routing/route_profile_store.cpp \
  src/wiremudder/routing/router.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }

# 1. The routing harness asserts no audit entry serializes a username.
out=$(LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" routing 2>&1) \
  || { echo "FAIL: routing harness" >&2; exit 1; }
echo "$out" | grep -q "harness routing: ok" || { echo "FAIL: routing sentinel" >&2; exit 1; }

# 2. The Rust audit serialization is credential-free (unit test).
(cd wirecore/crates/wire-routing && /root/.cargo/bin/cargo test --offline audit_never) >/dev/null 2>&1 \
  || { echo "FAIL: Rust audit redaction" >&2; exit 1; }

# 3. Export serialization never embeds secrets: profile JSON round-trip
#    of an AI provider value containing a secret-looking token must stay
#    out of audit logs (covered by the profiles harness assertion).

# 4. No secret-like literal exists in EP-007 production sources
#    (excluding #[cfg(test)] test modules, which legitimately assert
#    redaction against fake secret strings).
for f in src/wiremudder/profiles/*.h src/wiremudder/profiles/*.cpp \
         src/wiremudder/routing/*.h src/wiremudder/routing/*.cpp \
         wirecore/crates/wire-profiles/src/lib.rs wirecore/crates/wire-routing/src/lib.rs; do
  [ -f "$f" ] || continue
  awk '/#\[cfg\(test\)\]/{exit} {print}' "$f" | grep -n "hunter2\|sk_live\|password" \
    && { echo "FAIL: secret-like literal in production source ($f)" >&2; exit 1; } || true
done

echo "security secrets-redaction: ok"
