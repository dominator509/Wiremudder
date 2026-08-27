// WireMudder EP-005 M3 integration/E2E harness.
//
// Drives the REAL WireCoreSupervisor (src/wiremudder/bridge/
// wirecore_bridge.cpp) against the REAL Rust sidecar binary over a
// real Unix domain socket. There is no mock, stub, or simulated peer
// anywhere in this harness: "absent sidecar" is produced by pointing
// the supervisor at a path that does not exist, and "crash" is a real
// SIGKILL delivered to the real sidecar process.
//
// Subcommands:
//   lifecycle <socket>            full session: hello, request, snapshot,
//                                 cancel, health, shutdown
//   crash <socket> <binary>       kill -9 sidecar; supervisor restarts
//   e2e <socket> <binary>         P0 gameplay loop survives absent +
//                                 crashed WireCore; work flows when up

#include "src/wiremudder/bridge/wirecore_bridge.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QThread>
#include <QTimer>

#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <functional>

using wiremudder::FrameKind;
using wiremudder::WireCoreSupervisor;

namespace {

bool g_fail = false;
QString g_failReason;

void fail(const QString& reason) {
    g_fail = true;
    g_failReason = reason;
    fprintf(stderr, "HARNESS FAIL: %s\n", qPrintable(reason));
}

// Drive the Qt event loop until cond() is true or timeout elapses.
bool waitFor(const std::function<bool()>& cond, int timeoutMs) {
    QElapsedTimer timer;
    timer.start();
    while (!cond()) {
        if (timer.elapsed() > timeoutMs) return false;
        QCoreApplication::processEvents(QEventLoop::AllEvents, 50);
        QThread::msleep(5);
    }
    return true;
}

bool runLifecycle(const QString& socketPath, const QString& binary) {
    WireCoreSupervisor sup(socketPath);
    QHash<QString, QJsonObject> responses;
    bool readyOk = false;

    sup.setReadyCallback([&](bool ok, const QString& err) {
        readyOk = ok;
        if (!ok) fail("ready failed: " + err);
    });
    sup.setFrameCallback([&](const QByteArray& line) {
        if (qEnvironmentVariableIsSet("WM_DEBUG"))
            fprintf(stderr, "RX: %s\n", line.constData());
        const QJsonObject frame = QJsonDocument::fromJson(line).object();
        const QString fid = frame.value("frame_id").toString();
        if (!fid.isEmpty()) {
            // The sidecar replies with the request's frame_id; reply
            // kinds differ by request (response vs snapshot).
            responses.insert(fid, frame.value("payload").toObject());
        }
    });

    if (!sup.start(binary)) fail("start returned false");
    if (!waitFor([&]() { return readyOk || g_fail; }, 4000)) fail("no ready");

    // Request/response over the real queue.
    sup.postRequest(FrameKind::Request, "life-0001",
                    QJsonDocument(QJsonObject{{"op", "echo"}, {"text", "hello"}})
                        .toJson(QJsonDocument::Compact));
    if (!waitFor([&]() { return responses.contains("life-0001"); }, 3000))
        fail("no response to request");
    if (responses.value("life-0001").value("accepted").toBool() != true)
        fail("request not accepted");

    // Snapshot of the bounded queue.
    sup.postRequest(FrameKind::Snapshot, "snap-0001",
                    QByteArray("{}"));
    if (!waitFor([&]() { return responses.contains("snap-0001"); }, 3000))
        fail("no snapshot response");
    if (!responses.value("snap-0001").contains("queue_len"))
        fail("snapshot missing queue_len");

    // Cancellation discards queued work.
    sup.postRequest(FrameKind::Cancel, "canc-0001", QByteArray("{}"));
    if (!waitFor([&]() { return responses.contains("canc-0001"); }, 3000))
        fail("no cancel response");
    if (responses.value("canc-0001").value("cancelled").toBool() != true)
        fail("cancel not acknowledged");

    // Health: a real ping/pong cycle must make the supervisor healthy.
    if (!waitFor([&]() { return sup.healthy(); }, 6000))
        fail("sidecar never became healthy");

    // Clean shutdown: sidecar process must exit.
    const qint64 pid = sup.pid();
    sup.stop();
    if (!waitFor([&]() { return ::kill(static_cast<pid_t>(pid), 0) != 0; }, 3000)) {
        fail("sidecar still alive after stop");
    }
    if (g_fail) return false;
    printf("integration bridge-lifecycle: ok\n");
    return true;
}

bool runCrashRestart(const QString& socketPath, const QString& binary) {
    WireCoreSupervisor sup(socketPath);
    bool readyOk = false;
    int readyCount = 0;
    bool crashed = false;

    sup.setReadyCallback([&](bool ok, const QString& err) {
        readyOk = ok;
        readyCount++;
        if (!ok) fail("ready failed: " + err);
    });
    sup.setCrashCallback([&]() { crashed = true; });

    if (!sup.start(binary)) fail("start returned false");
    if (!waitFor([&]() { return readyOk && sup.isConnected(); }, 4000))
        fail("no initial ready");

    const qint64 pid = sup.pid();
    if (pid <= 0) fail("no sidecar pid");
    if (::kill(static_cast<pid_t>(pid), SIGKILL) != 0) fail("kill failed");

    // Supervisor must observe the crash...
    if (!waitFor([&]() { return crashed; }, 4000)) fail("no crash callback");

    // ...and restart the sidecar with a fresh handshake.
    if (!waitFor([&]() { return readyCount >= 2 && sup.isConnected(); }, 8000))
        fail("no restart handshake");
    if (!waitFor([&]() { return sup.healthy(); }, 6000))
        fail("restarted sidecar unhealthy");

    sup.stop();
    if (g_fail) return false;
    printf("integration bridge-crash-restart: ok\n");
    return true;
}

bool runHangDetection(const QString& socketPath, const QString& binary) {
    WireCoreSupervisor sup(socketPath);
    bool readyOk = false;
    int readyCount = 0;
    bool crashed = false;

    sup.setReadyCallback([&](bool ok, const QString& err) {
        readyOk = ok;
        readyCount++;
        if (qEnvironmentVariableIsSet("WM_DEBUG"))
            fprintf(stderr, "HANG ready#%d ok=%d err=%s\n", readyCount, ok ? 1 : 0, qPrintable(err));
        if (!ok) fail("ready failed: " + err);
    });
    sup.setCrashCallback([&]() {
        crashed = true;
        if (qEnvironmentVariableIsSet("WM_DEBUG")) fprintf(stderr, "HANG crash fired\n");
    });

    if (!sup.start(binary)) fail("start returned false");
    if (!waitFor([&]() { return readyOk && sup.isConnected(); }, 4000))
        fail("no initial ready");

    const qint64 pid = sup.pid();
    if (pid <= 0) fail("no sidecar pid");

    // Simulate a hang (not a crash): freeze the sidecar with SIGSTOP.
    // The supervisor must detect stale pings and restart it.
    if (::kill(static_cast<pid_t>(pid), SIGSTOP) != 0) fail("SIGSTOP failed");

    // Stale-pong detection: health timer pings every 2 s; staleness
    // threshold is 6 s. Allow up to 14 s for detect + restart.
    if (!waitFor([&]() { return crashed; }, 14000)) fail("no hang detected");
    if (!waitFor([&]() { return readyCount >= 2 && sup.isConnected(); }, 8000))
        fail("no restart after hang");
    if (!waitFor([&]() { return sup.healthy(); }, 6000))
        fail("restarted sidecar unhealthy");

    sup.stop();
    if (g_fail) return false;
    printf("failure hang-detection: ok\n");
    return true;
}

bool runE2e(const QString& socketPath, const QString& binary) {
    WireCoreSupervisor sup(socketPath);
    bool readyOk = false;
    bool readyErr = false;
    bool crashed = false;
    QHash<QString, QJsonObject> responses;

    // P0 manual gameplay loop: a 100 ms timer that must never stall.
    // If the bridge ever blocked the main thread, this gap blows out.
    qint64 lastTick = 0;
    qint64 maxGap = 0;
    QTimer p0;
    p0.setInterval(100);
    QObject::connect(&p0, &QTimer::timeout, [&]() {
        const qint64 now = QDateTime::currentMSecsSinceEpoch();
        if (lastTick != 0) maxGap = qMax(maxGap, now - lastTick);
        lastTick = now;
    });
    p0.start();

    sup.setReadyCallback([&](bool ok, const QString& err) {
        readyOk = ok;
        if (!ok) readyErr = true;
    });
    sup.setCrashCallback([&]() { crashed = true; });
    sup.setFrameCallback([&](const QByteArray& line) {
        const QJsonObject frame = QJsonDocument::fromJson(line).object();
        const QString fid = frame.value("frame_id").toString();
        if (!fid.isEmpty()) {
            responses.insert(fid, frame.value("payload").toObject());
        }
    });

    // Phase 1: WireCore absent. The supervisor reports a disabled
    // state; manual gameplay continues with no stall.
    if (!sup.start("/nonexistent/wirecore-runtime")) fail("absent start false");
    if (!waitFor([&]() { return readyErr; }, 4000)) fail("absent not reported");
    if (sup.healthy()) fail("absent sidecar reported healthy");
    if (sup.postRequest(FrameKind::Request, "e2e-00001", QByteArray("{}")))
        fail("absent sidecar accepted a request");
    QCoreApplication::processEvents();
    const qint64 gapAfterAbsent = maxGap;
    if (gapAfterAbsent > 400) fail("P0 stalled during absent phase");

    // Phase 2: real sidecar up; optional work flows.
    readyOk = false;
    readyErr = false;
    if (!sup.start(binary)) fail("real start false");
    if (!waitFor([&]() { return readyOk && sup.isConnected(); }, 4000))
        fail("no ready with real sidecar");
    sup.postRequest(FrameKind::Request, "e2e-00002",
                    QJsonDocument(QJsonObject{{"op", "echo"}})
                        .toJson(QJsonDocument::Compact));
    if (!waitFor([&]() { return responses.contains("e2e-00002"); }, 3000))
        fail("no response in up phase");
    if (!waitFor([&]() { return sup.healthy(); }, 6000))
        fail("sidecar never healthy");

    // Phase 3: crash the sidecar mid-session. Supervisor restarts it;
    // the P0 loop never stalls and work flows again.
    const qint64 pid = sup.pid();
    if (pid <= 0) fail("no pid before crash");
    if (::kill(static_cast<pid_t>(pid), SIGKILL) != 0) fail("kill failed");
    if (!waitFor([&]() { return crashed; }, 4000)) fail("no crash observed");
    if (!waitFor([&]() { return sup.isConnected(); }, 8000))
        fail("no restart after crash");
    const qint64 gapAfterCrash = maxGap;
    if (gapAfterCrash > 400) fail("P0 stalled during crash phase");

    sup.postRequest(FrameKind::Request, "e2e-00003",
                    QJsonDocument(QJsonObject{{"op", "echo"}})
                        .toJson(QJsonDocument::Compact));
    if (!waitFor([&]() { return responses.contains("e2e-00003"); }, 3000))
        fail("no response after restart");

    p0.stop();
    sup.stop();
    if (g_fail) return false;
    printf("e2e optional-failure-preserves-gameplay: ok\n");
    return true;
}

}  // namespace

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    if (argc < 3) {
        fprintf(stderr, "usage: %s lifecycle <socket> <binary>\n", argv[0]);
        fprintf(stderr, "       %s crash <socket> <binary>\n", argv[0]);
        fprintf(stderr, "       %s e2e <socket> <binary>\n", argv[0]);
        return 2;
    }
    const QString cmd = QString::fromLocal8Bit(argv[1]);
    const QString socketPath = QString::fromLocal8Bit(argv[2]);
    const QString binary = argc >= 4 ? QString::fromLocal8Bit(argv[3]) : QString();

    bool ok = false;
    if (cmd == "lifecycle") {
        ok = runLifecycle(socketPath, binary);
    } else if (cmd == "crash") {
        ok = runCrashRestart(socketPath, binary);
    } else if (cmd == "hang") {
        ok = runHangDetection(socketPath, binary);
    } else if (cmd == "e2e") {
        ok = runE2e(socketPath, binary);
    } else {
        fprintf(stderr, "unknown subcommand: %s\n", qPrintable(cmd));
        return 2;
    }
    return ok ? 0 : 1;
}
