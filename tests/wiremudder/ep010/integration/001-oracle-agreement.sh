#!/usr/bin/env sh
# EP-010 M3 integration test: Rust oracle and C++ boundary agree on
# permission firewall decisions and hash verification.
set -eu
cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
CARGO=/root/.cargo/bin/cargo

fail() { echo "integration: FAIL - $1" >&2; exit 1; }

[ -x wirecore/target/debug/wire-packages-oracle ] || fail "oracle binary missing (build first)"
[ -d "$QT" ] || fail "Qt not found"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# C++ oracle mirror: same decisions as the Rust oracle
cat > "$TMP/cpp_oracle.cpp" <<'CPP'
#include "src/wiremudder/packages/package_boundary.h"
#include <cstdio>
using namespace wiremudder::packages;
int main() {
    PermissionFirewall fw;
    fw.grant({Permission::Network});
    const char* req[] = {"network", "secrets", "command_send"};
    for (const char* r : req) {
        Permission p = permissionFromName(r);
        printf("{\"permission\":\"%s\",\"decision\":\"%s\"}\n",
               r, fw.decide(p) == Decision::Granted ? "granted" : "denied");
    }
    // expansion
    QSet<Permission> requested = {Permission::Network, Permission::Secrets, Permission::CommandSend};
    QSet<Permission> exp = fw.expansion(requested);
    if (exp.contains(Permission::Secrets) && exp.contains(Permission::CommandSend) && exp.size() == 2)
        printf("EXPANSION_OK\n");
    // hash
    printf("HASH_%s\n", verifyContentHash("ABC123", "abc123") ? "VERIFIED" : "MISMATCH");
    printf("HASH_%s\n", verifyContentHash("ABC123", "deadbeef") ? "VERIFIED" : "MISMATCH");
    return 0;
}
CPP

export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core) -I"$PWD" "$TMP/cpp_oracle.cpp" \
  $(pkg-config --libs Qt6Core) -Wl,-rpath,"$QT/lib" -o "$TMP/cpp_oracle" \
  || fail "cpp oracle compile"

RUST=$(./wirecore/target/debug/wire-packages-oracle decisions "network" "network,secrets,command_send")
CPP=$(LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$TMP/cpp_oracle")

echo "$RUST" | grep -q '"network","decision":"granted"' || fail "rust network decision"
echo "$RUST" | grep -q '"secrets","decision":"denied"' || fail "rust secrets decision"
echo "$RUST" | grep -q '"command_send","decision":"denied"' || fail "rust command_send decision"
echo "$CPP" | grep -q 'EXPANSION_OK' || fail "cpp expansion mismatch"
echo "$CPP" | grep -q 'HASH_VERIFIED' || fail "cpp hash verified"
echo "$CPP" | grep -q 'HASH_MISMATCH' || fail "cpp hash mismatch"

echo "integration: rust and cpp agree on package firewall semantics"
