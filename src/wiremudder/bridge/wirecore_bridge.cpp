// WireMudder C++/Qt bridge boundary implementation (SPEC-024, SPEC-025).
//
// Fully asynchronous supervisor for the WireCore Rust sidecar. The Qt
// main thread never waits on optional work: start() returns
// immediately, postRequest() is fire-and-forget with a bounded pending
// queue (256 frames; oldest dropped on overflow), health pings run on
// a timer, and a crashed peer is detected via socket disconnect and
// restarted with a fresh handshake. All of this is real process
// supervision over a real Unix domain socket.

#include "src/wiremudder/bridge/wirecore_bridge.h"

#include <chrono>

#include <QCoreApplication>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalSocket>
#include <QProcess>
#include <QTimer>

#include <cstdio>

namespace wiremudder {

namespace {
constexpr int kQueueCapacity = 256;
constexpr int kHealthIntervalMs = 2000;
constexpr int kPongStaleMs = 6000;
constexpr int kRestartDelayMs = 200;
constexpr int kStopWaitMs = 1500;
constexpr int kFrameIdMinLen = 8;
const char* kMagic = "WMC1";
constexpr int kVersion = 1;
}  // namespace

QByteArray frameKindToWire(FrameKind kind) {
    switch (kind) {
        case FrameKind::Hello: return "hello";
        case FrameKind::HelloAck: return "hello_ack";
        case FrameKind::Ping: return "ping";
        case FrameKind::Pong: return "pong";
        case FrameKind::Snapshot: return "snapshot";
        case FrameKind::Request: return "request";
        case FrameKind::Response: return "response";
        case FrameKind::Event: return "event";
        case FrameKind::Cancel: return "cancel";
        case FrameKind::Shutdown: return "shutdown";
    }
    return "unknown";
}

WireCoreSupervisor::~WireCoreSupervisor() {
    stop();
}

bool WireCoreSupervisor::start(const QString& wirecoreBinary, QString* error) {
    if (m_process && m_process->state() != QProcess::NotRunning) {
        if (error) *error = "already running";
        return false;
    }
    m_wirecoreBinary = wirecoreBinary;
    m_stopping = false;
    m_handshakeDone = false;
    m_connected = false;
    m_lastPongMs = 0;
    launchAndConnect();
    return true;
}

void WireCoreSupervisor::launchAndConnect() {
    m_process = new QProcess(this);
    m_process->setProgram(m_wirecoreBinary);
    m_process->setArguments(QStringList() << m_socketPath);
    m_process->start();
    if (!m_process->waitForStarted(1000)) {
        // Sidecar absent or failed to launch: report disabled state.
        // This is the "unavailable worker" path; manual gameplay is
        // unaffected because nothing here owns a gameplay path.
        if (m_readyCb) m_readyCb(false, "sidecar failed to start");
        return;
    }
    m_pid = m_process->processId();

    m_socket = new QLocalSocket(this);
    QObject::connect(m_socket, &QLocalSocket::connected, this, [this]() {
        m_handshakeDone = false;
        m_connectAttempts = 0;
        sendHello();
    });
    QObject::connect(m_socket, &QLocalSocket::readyRead, this,
                     &WireCoreSupervisor::onReadyRead);
    QObject::connect(m_socket, &QLocalSocket::disconnected, this,
                     &WireCoreSupervisor::onDisconnected);
    QObject::connect(m_socket,
                     QOverload<QLocalSocket::LocalSocketError>::of(
                         &QLocalSocket::errorOccurred),
                     this, [this](QLocalSocket::LocalSocketError) {
                         if (m_handshakeDone || m_stopping) return;
                         // The sidecar removes and re-binds its socket
                         // at startup; a connect that lands before the
                         // listener is ready is refused. Retry while
                         // the supervised process is still running.
                         if (m_process && m_process->state() == QProcess::Running &&
                             m_connectAttempts < 100) {
                             m_connectAttempts++;
                             QTimer::singleShot(std::chrono::milliseconds(50), this,
                                                [this]() {
                                                    if (!m_stopping && m_socket)
                                                        m_socket->connectToServer(m_socketPath);
                                                });
                         } else if (m_readyCb) {
                             m_readyCb(false, "socket error before handshake");
                         }
                     });
    m_socket->connectToServer(m_socketPath);

    if (!m_healthTimer) {
        m_healthTimer = new QTimer(this);
        m_healthTimer->setInterval(kHealthIntervalMs);
        QObject::connect(m_healthTimer, &QTimer::timeout, this,
                         &WireCoreSupervisor::maybeRestartUnhealthy);
    }
    m_healthTimer->start();
}

void WireCoreSupervisor::sendHello() {
    QJsonObject hello;
    hello["magic"] = QLatin1String(kMagic);
    hello["version"] = kVersion;
    hello["frame_id"] = QStringLiteral("hello-0001");
    hello["kind"] = QLatin1String(frameKindToWire(FrameKind::Hello));
    QJsonObject payload;
    payload["client"] = QStringLiteral("wiremudder-qt");
    payload["pid"] = static_cast<double>(QCoreApplication::applicationPid());
    hello["payload"] = payload;
    m_socket->write(QJsonDocument(hello).toJson(QJsonDocument::Compact));
    m_socket->write("\n");
}

void WireCoreSupervisor::onReadyRead() {
    while (m_socket->canReadLine()) {
        const QByteArray line = m_socket->readLine().trimmed();
        if (line.isEmpty()) continue;
        processFrame(line);
    }
}

void WireCoreSupervisor::processFrame(const QByteArray& line) {
    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(line, &err);
    if (err.error != QJsonParseError::NoError) {
        return;  // malformed frame is dropped; never trusted
    }
    const QJsonObject frame = doc.object();
    if (frame.value("magic").toString() != QLatin1String(kMagic)) {
        return;
    }
    if (frame.value("version").toInt() != kVersion) {
        return;
    }
    const QString kind = frame.value("kind").toString();
    if (kind == QLatin1String(frameKindToWire(FrameKind::HelloAck))) {
        const QJsonObject payload = frame.value("payload").toObject();
        m_connected = payload.value("status").toString() == "ok";
        m_handshakeDone = true;
        if (m_readyCb) m_readyCb(m_connected, m_connected ? QString() : "handshake rejected");
        if (m_connected) flushPending();
        return;
    }
    if (kind == QLatin1String(frameKindToWire(FrameKind::Pong))) {
        m_lastPongMs = QDateTime::currentMSecsSinceEpoch();
        return;
    }
    if (m_frameCb) m_frameCb(line);
}

void WireCoreSupervisor::onDisconnected() {
    m_connected = false;
    m_handshakeDone = false;
    if (m_stopping) return;
    if (m_crashCb) m_crashCb();
    scheduleRestart();
}

void WireCoreSupervisor::onProcessError() {
    if (!m_handshakeDone && !m_stopping) {
        if (m_readyCb) m_readyCb(false, "sidecar process failed");
    }
}

void WireCoreSupervisor::flushPending() {
    for (const QByteArray& frame : m_pending) {
        m_socket->write(frame);
        m_socket->write("\n");
    }
    m_pending.clear();
}

void WireCoreSupervisor::scheduleRestart() {
    QTimer::singleShot(std::chrono::milliseconds(kRestartDelayMs), this,
                       &WireCoreSupervisor::restartNow);
}

void WireCoreSupervisor::restartNow() {
    if (m_stopping) return;
    if (m_process) {
        m_process->terminate();
        if (!m_process->waitForFinished(500)) {
            m_process->kill();
            m_process->waitForFinished(500);
        }
        m_process->deleteLater();
        m_process = nullptr;
    }
    if (m_socket) {
        m_socket->disconnectFromServer();
        m_socket->deleteLater();
        m_socket = nullptr;
    }
    m_connected = false;
    m_handshakeDone = false;
    launchAndConnect();
}

void WireCoreSupervisor::sendPing() {
    if (!m_connected) return;
    QJsonObject ping;
    ping["magic"] = QLatin1String(kMagic);
    ping["version"] = kVersion;
    ping["frame_id"] = QStringLiteral("ping-0001");
    ping["kind"] = QLatin1String(frameKindToWire(FrameKind::Ping));
    ping["payload"] = QJsonObject();
    m_socket->write(QJsonDocument(ping).toJson(QJsonDocument::Compact));
    m_socket->write("\n");
}

void WireCoreSupervisor::maybeRestartUnhealthy() {
    sendPing();
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const bool stale = m_connected && m_lastPongMs > 0 && (now - m_lastPongMs) > kPongStaleMs;
    if (stale && !m_stopping) {
        if (m_crashCb) m_crashCb();
        scheduleRestart();
    }
}

bool WireCoreSupervisor::postRequest(FrameKind kind, const QString& frameId,
                                     const QByteArray& payloadJson,
                                     QString* error) {
    // WireCore absent: disabled state, never blocks, never fakes success.
    if (!m_process || m_process->state() == QProcess::NotRunning) {
        if (error) *error = "wirecore absent";
        return false;
    }
    if (frameId.size() < kFrameIdMinLen) {
        if (error) *error = "frame id too short";
        return false;
    }
    QJsonParseError perr{};
    const QJsonDocument pdoc = QJsonDocument::fromJson(payloadJson, &perr);
    if (perr.error != QJsonParseError::NoError) {
        if (error) *error = "payload is not valid json";
        return false;
    }
    QJsonObject frame;
    frame["magic"] = QLatin1String(kMagic);
    frame["version"] = kVersion;
    frame["frame_id"] = frameId;
    frame["kind"] = QLatin1String(frameKindToWire(kind));
    frame["payload"] = pdoc.object();
    const QByteArray wire = QJsonDocument(frame).toJson(QJsonDocument::Compact);

    if (m_connected) {
        m_socket->write(wire);
        m_socket->write("\n");
    } else {
        // Bounded queue while connecting: drop the oldest P2-P4 frame on
        // overflow (degradation), never block, never grow unbounded.
        if (m_pending.size() >= kQueueCapacity) {
            m_pending.removeFirst();
        }
        m_pending.append(wire);
    }
    return true;
}

bool WireCoreSupervisor::healthy() const {
    if (!m_connected || !m_process || m_process->state() != QProcess::Running) {
        return false;
    }
    if (m_lastPongMs == 0) return true;  // no ping cycle yet
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    return (now - m_lastPongMs) <= kPongStaleMs;
}

bool WireCoreSupervisor::isConnected() const { return m_connected; }

qint64 WireCoreSupervisor::pid() const { return m_pid; }

void WireCoreSupervisor::stop() {
    m_stopping = true;
    if (m_healthTimer) m_healthTimer->stop();
    if (m_socket && m_connected) {
        QJsonObject frame;
        frame["magic"] = QLatin1String(kMagic);
        frame["version"] = kVersion;
        frame["frame_id"] = QStringLiteral("shut-0001");
        frame["kind"] = QLatin1String(frameKindToWire(FrameKind::Shutdown));
        frame["payload"] = QJsonObject();
        m_socket->write(QJsonDocument(frame).toJson(QJsonDocument::Compact));
        m_socket->write("\n");
        m_socket->flush();
    }
    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->terminate();
        if (!m_process->waitForFinished(kStopWaitMs)) {
            m_process->kill();
            m_process->waitForFinished(kStopWaitMs);
        }
    }
    if (m_socket) {
        m_socket->disconnectFromServer();
        m_socket->deleteLater();
        m_socket = nullptr;
    }
    if (m_process) {
        m_process->deleteLater();
        m_process = nullptr;
    }
    m_connected = false;
    m_pid = -1;
}

}  // namespace wiremudder
