#!/usr/bin/env sh
# EP-011 M2 unit test: protocol boundary compiles, IAC parser invariants,
# capability detection.
set -eu
cd "$(dirname "$0")/../../../.."
QT=/opt/qt/6.8.2/gcc_64

fail() { echo "unit: FAIL - $1" >&2; exit 1; }

[ -d "$QT" ] || fail "Qt 6.8.2 not found"
[ -f src/wiremudder/protocol/protocol_boundary.h ] || fail "boundary header missing"
[ -f src/wiremudder/protocol/protocol_boundary.cpp ] || fail "boundary impl missing"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.cpp" <<'CPP'
#include "src/wiremudder/protocol/protocol_boundary.h"
#include <QByteArray>
#include <cassert>
#include <cstdio>
using namespace wiremudder::protocol;

int main() {
    // GMCP WILL + DO handshake: ff fb c9 ff fd c9
    QByteArray gmcp = QByteArray::fromHex("fffbc9fffdc9");
    QList<NegotiationEvent> ev = parseIac(gmcp);
    assert(ev.size() == 2);
    assert(ev[0].verb == cmd::WILL && ev[0].option == opt::GMCP);
    assert(ev[1].verb == cmd::DO && ev[1].option == opt::GMCP);

    QList<Capability> caps = detectCapabilities(ev);
    bool gmcpOk = false;
    for (const Capability& c : caps) {
        if (c.protocol == "GMCP") {
            assert(c.negotiated);
            assert(c.status == "negotiated");
            gmcpOk = true;
        }
    }
    assert(gmcpOk);

    // Escaped IAC (0xFF 0xFF) is not a negotiation verb.
    QByteArray esc = QByteArray::fromHex("ffff");
    assert(parseIac(esc).size() == 0);

    // Runaway SB is bounded, not a hang.
    QByteArray runaway = QByteArray::fromHex("fffa00c9" + QByteArray(8192, 'A').toHex());
    QList<NegotiationEvent> rev = parseIac(runaway);
    assert(rev.size() == 1);
    assert(rev[0].subdata.size() <= 4096);

    // Research protocols are declared without option bytes.
    QList<Capability> rcaps = detectCapabilities({});
    bool researchOk = false;
    for (const Capability& c : rcaps) {
        if (c.protocol == "MCP") { assert(c.status == "research"); researchOk = true; }
    }
    assert(researchOk);

    std::puts("protocol boundary invariants ok");
    return 0;
}
CPP

export PKG_CONFIG_PATH="$QT/lib/pkgconfig"
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt6Core) -I"$PWD" \
  "$TMP/main.cpp" src/wiremudder/protocol/protocol_boundary.cpp \
  $(pkg-config --libs Qt6Core) -Wl,-rpath,"$QT/lib" -o "$TMP/unit" \
  || fail "boundary compile"
LD_LIBRARY_PATH="$QT/lib:${LD_LIBRARY_PATH:-}" "$TMP/unit" || fail "boundary invariants"

echo "unit EP-011 M2: ok"
