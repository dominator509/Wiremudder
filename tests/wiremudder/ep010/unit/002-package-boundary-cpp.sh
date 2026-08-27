#!/usr/bin/env sh
# EP-010 M2 unit test: C++ package boundary compiles and invariants hold
# (default deny, expansion detection, quarantine, hash verify).
set -eu
cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64
[ -d "$QT" ] || fail() { :; }

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.cpp" <<'CPP'
#include "src/wiremudder/packages/package_boundary.h"
#include <cassert>
#include <cstdio>
using namespace wiremudder::packages;

int main() {
    // Default deny
    PermissionFirewall fw;
    assert(fw.decide(Permission::Network) == Decision::Denied);
    assert(fw.decide(Permission::Secrets) == Decision::Denied);

    // Grant lifts only requested
    fw.grant({Permission::Network});
    assert(fw.decide(Permission::Network) == Decision::Granted);
    assert(fw.decide(Permission::Secrets) == Decision::Denied);

    // Expansion detection
    QSet<Permission> requested = {Permission::Network, Permission::Secrets};
    QSet<Permission> expansion = fw.expansion(requested);
    assert(expansion.size() == 1);
    assert(expansion.contains(Permission::Secrets));

    // Quarantine
    Quarantine q;
    q.quarantine("hook1");
    assert(q.isQuarantined("hook1"));
    q.release("hook1");
    assert(!q.isQuarantined("hook1"));

    // Hash verify
    assert(verifyContentHash("ABC123", "abc123"));
    assert(!verifyContentHash("ABC123", "deadbeef"));

    // Permission name mapping
    assert(permissionName(Permission::CommandSend) == "command_send");
    assert(permissionFromName("ai_egress") == Permission::AiEgress);

    std::puts("cpp boundary invariants ok");
    return 0;
}
CPP

export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core) -I"$PWD" "$TMP/main.cpp" \
  $(pkg-config --libs Qt6Core) -Wl,-rpath,"$QT/lib" -o "$TMP/boundary" \
  || fail "boundary compile"
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$TMP/boundary" || fail "boundary invariants"

echo "unit EP-010 M2 boundary: ok"
