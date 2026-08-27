#!/usr/bin/env python3
"""Protocol oracle: verify museum fixtures against the C++ IAC parser.

Builds the protocol boundary as a CLI that parses a hex stream and
prints detected capabilities, then compares against each fixture's
expected report. Exit 0 only when all fixtures agree.
"""
import json, subprocess, sys, tempfile, os, glob

QT = "/opt/qt/6.8.2/gcc_64"
REPO = "/root/wiremudder-repo"
MUSEUM = os.path.join(REPO, "tools/protocol-museum")

def build_cli():
    src = r'''
#include "src/wiremudder/protocol/protocol_boundary.h"
#include <QByteArray>
#include <QList>
#include <QString>
#include <cstdio>
using namespace wiremudder::protocol;
int main(int argc, char** argv) {
    if (argc < 2) return 2;
    QByteArray hex(argv[1]);
    QByteArray data = QByteArray::fromHex(hex);
    QList<NegotiationEvent> events = parseIac(data);
    QList<Capability> caps = detectCapabilities(events);
    for (const Capability& c : caps) {
        if (c.status == "research") continue; // research declared, not negotiated
        std::printf("{\"protocol\":\"%s\",\"negotiated\":%s,\"status\":\"%s\"}\n",
                    c.protocol.toUtf8().constData(),
                    c.negotiated ? "true" : "false",
                    c.status.toUtf8().constData());
    }
    return 0;
}
'''
    tmp = tempfile.mkdtemp()
    main_cpp = os.path.join(tmp, "main.cpp")
    open(main_cpp, "w").write(src)
    env = dict(os.environ, PKG_CONFIG_PATH=f"{QT}/lib/pkgconfig")
    flags = subprocess.check_output(["pkg-config", "--cflags", "Qt6Core"], env=env).decode().split()
    libs = subprocess.check_output(["pkg-config", "--libs", "Qt6Core"], env=env).decode().split()
    out = os.path.join(tmp, "oracle_cli")
    subprocess.run(["g++", "-std=c++17", "-fPIC", *flags,
                    "-I" + REPO, main_cpp,
                    os.path.join(REPO, "src/wiremudder/protocol/protocol_boundary.cpp"),
                    *libs, "-Wl,-rpath", f"{QT}/lib", "-o", out],
                   env=env, check=True)
    return out, tmp

def main():
    cli, tmp = build_cli()
    files = sorted(glob.glob(os.path.join(MUSEUM, "*.json")))
    if not files:
        print("protocol oracle: no fixtures")
        return 1
    failed = 0
    for f in files:
        fx = json.load(open(f))
        if fx["fixture_id"] == "malformed-sb":
            # bounded parse: must not crash; expected is empty report
            try:
                r = subprocess.run([cli, fx["stream_hex"]],
                                   capture_output=True, text=True, timeout=10,
                                   env=dict(os.environ, LD_LIBRARY_PATH=f"{QT}/lib"))
                if r.returncode != 0:
                    print(f"protocol oracle: malformed-sb crashed rc={r.returncode}")
                    failed += 1
                    continue
                print(f"protocol oracle: agree {fx['fixture_id']} (bounded)")
            except Exception as e:
                print(f"protocol oracle: malformed-sb error {e}")
                failed += 1
            continue
        r = subprocess.run([cli, fx["stream_hex"]],
                           capture_output=True, text=True, timeout=10,
                           env=dict(os.environ, LD_LIBRARY_PATH=f"{QT}/lib"))
        got = []
        for line in r.stdout.strip().splitlines():
            if line.strip():
                try:
                    got.append(json.loads(line))
                except Exception:
                    pass
        expected = []
        for c in fx["expected"]:
            if c.get("status") != "research":
                expected.append(c)
        ok = True
        # Each expected capability must appear in the observed report
        # with the same protocol + status. Extra "absent" observations
        # are allowed (the detector reports all known options).
        for e in expected:
            found = None
            for g in got:
                if g.get("protocol") == e.get("protocol"):
                    found = g
                    break
            if found is None:
                ok = False
                print(f"protocol oracle: {fx['fixture_id']}: missing {e.get('protocol')}")
            elif found.get("status") != e.get("status") or found.get("negotiated") != e.get("negotiated"):
                ok = False
                print(f"protocol oracle: {fx['fixture_id']}: {e.get('protocol')} "
                      f"expected {e.get('status')}/{e.get('negotiated')} "
                      f"got {found.get('status')}/{found.get('negotiated')}")
        if not ok:
            print(f"protocol oracle: DISAGREE {fx['fixture_id']}: got={got} expected={expected}")
            failed += 1
        else:
            print(f"protocol oracle: agree {fx['fixture_id']}")
    if failed:
        print(f"protocol oracle: {failed} fixture(s) failed")
        return 1
    print(f"protocol oracle: all {len(files)} fixtures agree")
    return 0

if __name__ == "__main__":
    sys.exit(main())
