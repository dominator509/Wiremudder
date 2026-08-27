#!/usr/bin/env sh
# EP-006 M3 E2E: cross-implementation egress policy oracle.
# The Rust wire-privacy core and the C++ PrivacyFirewall are both real
# implementations of the same SPEC-010 rules; this test feeds the same
# policy matrix to both and requires identical decisions.
set -eu

cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
HARNESS=/tmp/wm-ep006-m3-e2e-harness-$$
RUST_OUT=/tmp/wm-ep006-m3-e2e-rust.txt
CPP_OUT=/tmp/wm-ep006-m3-e2e-cpp.txt
trap 'rm -f "$HARNESS" "$RUST_OUT" "$CPP_OUT"' EXIT

# 1. Rust side: real wire-privacy crate prints the matrix.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo run --quiet \
  --manifest-path wirecore/crates/wire-privacy/Cargo.toml \
  --example policy_matrix > "$RUST_OUT" 2>/dev/null \
  || { echo "FAIL: rust policy matrix" >&2; exit 1; }

# 2. C++ side: real PrivacyFirewall prints the same matrix.
[ -d "$QT" ] || { echo "FAIL: Qt 6.8.2 not at $QT" >&2; exit 1; }
export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core Qt6Network) \
  -I/usr/include/qt6keychain -I"$PWD" \
  tests/wiremudder/ep006/harness/privacy_harness.cpp \
  src/wiremudder/privacy/privacy_firewall.cpp \
  src/wiremudder/privacy/secret_vault.cpp \
  $(pkg-config --libs Qt6Core Qt6Network) -lqt6keychain \
  -Wl,-rpath,"$QT/lib" -o "$HARNESS" \
  || { echo "FAIL: harness compile" >&2; exit 1; }
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$HARNESS" e2e > "$CPP_OUT" 2>&1 \
  || { echo "FAIL: cpp matrix" >&2; exit 1; }

# 3. Identical decisions, same order.
if ! diff -u "$RUST_OUT" "$CPP_OUT"; then
  echo "FAIL: cross-implementation policy divergence" >&2
  exit 1
fi
echo "e2e egress-lockdown: ok ($(wc -l < "$CPP_OUT") decisions identical)"
