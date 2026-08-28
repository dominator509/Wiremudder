// WireMudder C++/Qt bridge boundary (SPEC-024).
//
// Declares the minimal C++ side of the WireCore bridge. The Qt client
// talks to the supervised Rust sidecar over a local Unix domain socket
// using versioned JSON frames. The Qt main thread never waits on
// optional WireCore work: requests are fire-and-forget with a bounded
// queue and a deadline on the caller side.
//
// The implementation (wirecore_bridge.cpp) is fully asynchronous: the
// supervisor launches the sidecar, connects, handshakes, health-pings,
// and restarts on crash without ever blocking the caller. Frame
// handling follows schemas/wiremudder/bridge/frame.schema.json.
//
// This header and its implementation are the C++ surface EP-005 owns;
// no inherited source is modified by the bridge.

#ifndef WIREMUDDER_BRIDGE_WIRECORE_BRIDGE_H
#define WIREMUDDER_BRIDGE_WIRECORE_BRIDGE_H

#include <QByteArray>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVector>

#include <functional>

class QLocalSocket;
class QProcess;
class QTimer;

namespace wiremudder {

// Bridge frame kinds mirroring schemas/wiremudder/bridge/frame.schema.json.
enum class FrameKind { Hello, HelloAck, Ping, Pong, Snapshot, Request, Response, Event, Cancel, Shutdown };

// A small RAII guard that keeps WireCore alive for the lifetime of the
// client and shuts it down cleanly. It does not own any gameplay path.
//
// Lifecycle:
//   start() launches the sidecar and connects asynchronously.
//   readyCallback(ok, error) fires once the hello handshake settles.
//   crashCallback() fires when the peer dies unexpectedly; the
//   supervisor restarts it and readyCallback fires again.
//   stop() sends shutdown, waits a bounded time, then kills if needed.
class WireCoreSupervisor final : public QObject
{
public:
    using ReadyCallback = std::function<void(bool ok, const QString& error)>;
    using CrashCallback = std::function<void()>;
    using FrameCallback = std::function<void(const QByteArray& jsonFrame)>;

    explicit WireCoreSupervisor(QString socketPath, QObject* parent = nullptr)
    : QObject(parent)
    , m_socketPath(std::move(socketPath))
    {
    }
    ~WireCoreSupervisor();

    WireCoreSupervisor(const WireCoreSupervisor&) = delete;
    WireCoreSupervisor& operator=(const WireCoreSupervisor&) = delete;

    // Start the sidecar process (found at wirecoreBinary) and connect.
    // Returns immediately; readiness is reported through readyCallback.
    bool start(const QString& wirecoreBinary, QString* error = nullptr);

    // Optional work: enqueue a request frame; returns immediately.
    // Never blocks the caller. Returns false when WireCore is absent.
    bool postRequest(FrameKind kind, const QString& frameId, const QByteArray& payloadJson, QString* error = nullptr);

    // Snapshot health without blocking.
    bool healthy() const;

    // True once the hello handshake has completed.
    bool isConnected() const;

    // PID of the supervised sidecar process, or -1 when not running.
    qint64 pid() const;

    void stop();

    void setReadyCallback(ReadyCallback cb) { m_readyCb = std::move(cb); }
    void setCrashCallback(CrashCallback cb) { m_crashCb = std::move(cb); }
    void setFrameCallback(FrameCallback cb) { m_frameCb = std::move(cb); }

private:
    void launchAndConnect();
    void sendHello();
    void onReadyRead();
    void onDisconnected();
    void onProcessError();
    void flushPending();
    void scheduleRestart();
    void restartNow();
    void sendPing();
    void maybeRestartUnhealthy();
    void processFrame(const QByteArray& line);

    QString m_socketPath;
    QString m_wirecoreBinary;
    QProcess* m_process = nullptr;
    QLocalSocket* m_socket = nullptr;
    QTimer* m_healthTimer = nullptr;
    QVector<QByteArray> m_pending; // bounded (256) P2-P4 queue
    qint64 m_lastPongMs = 0;
    qint64 m_pid = -1;
    int m_connectAttempts = 0;
    bool m_connected = false;
    bool m_stopping = false;
    bool m_handshakeDone = false;
    bool m_restartPending = false;

    ReadyCallback m_readyCb;
    CrashCallback m_crashCb;
    FrameCallback m_frameCb;
};

// Convert a bridge frame kind to its on-wire snake_case name.
QByteArray frameKindToWire(FrameKind kind);

} // namespace wiremudder

#endif // WIREMUDDER_BRIDGE_WIRECORE_BRIDGE_H
