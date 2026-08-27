#!/usr/bin/env sh
# LF-006 local-only-lockdown (live-fire)
#
# Proves the real user outcome of EP-006: Local Only Lockdown denies
# all declared remote egress, consent is scoped/revocable/audited,
# secrets are protected and never leak, and both real implementations
# (Rust core + C++ Qt adapter) agree on every policy decision.
set -eu
fail() { echo "LF-006: FAIL - $1" >&2; exit 1; }

cd "$(dirname "$0")/../.."
QT=/opt/qt/6.8.2/gcc_64
[ -d "$QT" ] || fail "Qt 6.8.2 not at $QT"
HARNESS=/tmp/wm-lf006-harness-$$
trap 'rm -f "$HARNESS"' EXIT

echo "LF-006: local-only-lockdown"
echo "observed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. Real Rust cores: full test suites (denial-first, consent,
#    redaction, secrets abuse cases).
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-privacy/Cargo.toml >/tmp/wm-lf006-p.log 2>&1 \
  || fail "wire-privacy tests"
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-secrets/Cargo.toml >/tmp/wm-lf006-s.log 2>&1 \
  || fail "wire-secrets tests"

# 2. Real C++ adapter: firewall + vault invariants.
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I/usr/include/qt6keychain -I"$PWD" \
  tests/wiremudder/ep006/harness/privacy_harness.cpp \
  src/wiremudder/privacy/privacy_firewall.cpp \
  src/wiremudder/privacy/secret_vault.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -lqt6keychain \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" || fail "harness compile"
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" firewall >/tmp/wm-lf006-fw.out 2>&1 \
  || fail "firewall invariants"
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" vault >/tmp/wm-lf006-v.out 2>&1 \
  || fail "vault invariants"

# 3. Cross-implementation oracle: identical denial-first decisions.
sh tests/wiremudder/ep006/e2e/001-egress-lockdown.sh >/dev/null 2>&1 \
  || fail "egress matrix divergence"

# 4. No secret value in any live-fire output.
if grep -q "hunter2\|tok-1234\|sk-abc" /tmp/wm-lf006-fw.out /tmp/wm-lf006-v.out 2>/dev/null; then
  fail "secret leaked to live-fire output"
fi

echo "LF-006: local-only-lockdown ok"
