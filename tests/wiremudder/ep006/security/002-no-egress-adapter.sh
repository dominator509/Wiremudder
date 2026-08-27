#!/usr/bin/env sh
# EP-006 M4 security test: no egress adapter exists in this node and
# the denial-first matrix holds on both implementations.
set -eu

cd "$(dirname "$0")/../../../.."

# 1. The privacy surface must contain NO network/egress code: the
#    firewall is denial-first by construction, and no adapter may
#    bypass it (acceptance obligation 6).
if grep -rn "QNetworkAccessManager\|QTcpSocket\|QUdpSocket\|connectToHost\|http" \
     src/wiremudder/privacy/ 2>/dev/null | grep -v "https://api.example.com" | grep -v "^\s*//"; then
  echo "FAIL: network/egress code found in privacy surface" >&2; exit 1
fi

# 2. The denial-first matrix still holds on both implementations.
sh tests/wiremudder/ep006/e2e/001-egress-lockdown.sh >/dev/null 2>&1 \
  || { echo "FAIL: egress matrix divergence" >&2; exit 1; }

# 3. The Rust core's default posture denies everything.
CARGO_TARGET_DIR="$PWD/wirecore/target" /root/.cargo/bin/cargo test \
  --manifest-path wirecore/crates/wire-privacy/Cargo.toml lockdown_denies_by_default 2>&1 \
  | grep -q "test result: ok" || { echo "FAIL: lockdown default test" >&2; exit 1; }
echo "security no-egress-adapter: ok"
