// EP-011 M3 test harness: exercises the real Telnet IAC protocol boundary
// against controlled local fixtures and verifies capability detection.
// Subcommands:
//   parse <hex>                parse IAC byte stream, print events
//   detect <hex>               parse + detect capabilities, print table
//   netflow <host> <port> <proto>   connect, negotiate, require <proto>
//   manualflow <host> <port>        connect, round-trip text (gameplay)
#include <QByteArray>
#include <QCoreApplication>
#include <QElapsedTimer>
#include <QList>
#include <QString>
#include <QTcpSocket>
#include <QThread>
#include <cstdio>
#include <cstdlib>

#include "src/wiremudder/protocol/protocol_boundary.h"

using namespace wiremudder::protocol;

static int fail(const char* msg) {
    std::fprintf(stderr, "FAIL: %s\n", msg);
    return 1;
}

static QByteArray hexToBytes(const QString& hex) {
    QByteArray out;
    const QString clean = hex.trimmed().remove(' ');
    for (int i = 0; i + 1 < clean.size(); i += 2) {
        bool ok = false;
        out.append(static_cast<char>(clean.mid(i, 2).toInt(&ok, 16)));
        if (!ok) break;
    }
    return out;
}

static int cmdParse(const QString& hex) {
    const QByteArray data = hexToBytes(hex);
    const QList<NegotiationEvent> events = parseIac(data);
    std::printf("events=%lld\n", static_cast<long long>(events.size()));
    for (const NegotiationEvent& e : events) {
        const QString verb = (e.verb == cmd::DO ? "DO" :
                              e.verb == cmd::DONT ? "DONT" :
                              e.verb == cmd::WILL ? "WILL" :
                              e.verb == cmd::WONT ? "WONT" :
                              e.verb == cmd::SB ? "SB" : "?");
        std::printf("%s %s pos=%d sub=%lld\n", qPrintable(verb),
                    qPrintable(optionName(e.option)), e.position,
                    static_cast<long long>(e.subdata.size()));
    }
    return 0;
}

static int cmdDetect(const QString& hex) {
    const QByteArray data = hexToBytes(hex);
    const QList<NegotiationEvent> events = parseIac(data);
    const QList<Capability> caps = detectCapabilities(events);
    std::printf("caps=%lld\n", static_cast<long long>(caps.size()));
    for (const Capability& c : caps) {
        std::printf("%s %s %s\n", qPrintable(c.protocol),
                    c.negotiated ? "yes" : "no", qPrintable(c.status));
    }
    return 0;
}

// Connect to a host/port, read whatever the server sends, parse it, and
// require the named protocol to be negotiated. Returns 0 on success.
static int cmdNetflow(const QString& host, quint16 port, const QString& want) {
    QTcpSocket sock;
    sock.connectToHost(host, port);
    if (!sock.waitForConnected(5000)) return fail("connect");
    // Read until 2s of silence or 64KiB.
    QByteArray buf;
    while (buf.size() < 65536) {
        if (!sock.waitForReadyRead(2000)) break;
        buf += sock.readAll();
    }
    sock.disconnectFromHost();
    const QList<NegotiationEvent> events = parseIac(buf);
    const QList<Capability> caps = detectCapabilities(events);
    for (const Capability& c : caps) {
        std::printf("%s %s\n", qPrintable(c.protocol), qPrintable(c.status));
        if (c.protocol == want && c.negotiated) return 0;
    }
    return fail(qPrintable(QStringLiteral("protocol %1 not negotiated").arg(want)));
}

// Connect, send a text line, expect an echo back. Proves manual text
// gameplay works even when the byte stream contains protocol garbage.
static int cmdManualflow(const QString& host, quint16 port) {
    QTcpSocket sock;
    sock.connectToHost(host, port);
    if (!sock.waitForConnected(5000)) return fail("connect");
    sock.waitForReadyRead(2000); // drain negotiation bytes
    (void)sock.readAll();
    const QByteArray line = "hello manual gameplay\n";
    sock.write(line);
    if (!sock.waitForBytesWritten(2000)) return fail("write");
    QByteArray echo;
    if (!sock.waitForReadyRead(5000)) return fail("echo read timeout");
    echo = sock.readAll();
    sock.disconnectFromHost();
    if (!echo.contains("hello manual gameplay")) {
        std::fprintf(stderr, "FAIL: echo mismatch: %s\n", echo.left(64).constData());
        return 1;
    }
    std::printf("manual echo: ok (%lld bytes)\n", static_cast<long long>(echo.size()));
    return 0;
}

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    if (argc < 2) { std::fprintf(stderr, "usage: harness parse|detect|netflow|manualflow\n"); return 2; }
    const QString cmd = QString::fromUtf8(argv[1]);
    if (cmd == "parse" && argc >= 3) return cmdParse(QString::fromUtf8(argv[2]));
    if (cmd == "detect" && argc >= 3) return cmdDetect(QString::fromUtf8(argv[2]));
    if (cmd == "netflow" && argc >= 5) {
        return cmdNetflow(QString::fromUtf8(argv[2]), static_cast<quint16>(QString::fromUtf8(argv[3]).toUInt()),
                          QString::fromUtf8(argv[4]));
    }
    if (cmd == "manualflow" && argc >= 4) {
        return cmdManualflow(QString::fromUtf8(argv[2]), static_cast<quint16>(QString::fromUtf8(argv[3]).toUInt()));
    }
    std::fprintf(stderr, "bad args\n");
    return 2;
}
