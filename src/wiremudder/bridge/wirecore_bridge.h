// WireMudder C++/Qt bridge boundary (SPEC-024).
//
// Declares the minimal C++ side of the WireCore bridge. The Qt client
// talks to the supervised Rust sidecar over a local Unix domain socket
// using versioned JSON frames. The Qt main thread never blocks on
// optional WireCore work: requests are fire-and-forget with a bounded
// queue and deadline on the caller side.
//
// This header is the only C++ surface EP-005 owns; no inherited source
// is modified by the bridge.

#ifndef WIREMUDDER_BRIDGE_WIRECORE_BRIDGE_H
#define WIREMUDDER_BRIDGE_WIRECORE_BRIDGE_H

#include <QObject>
#include <QString>
#include <QStringList>

namespace wiremudder {

// Bridge frame kinds mirroring schemas/wiremudder/bridge/frame.schema.json.
enum class FrameKind {
    Hello,
    HelloAck,
    Ping,
    Pong,
    Snapshot,
    Request,
    Response,
    Event,
    Cancel,
    Shutdown
};

// A small RAII guard that keeps WireCore alive for the lifetime of the
// client and shuts it down cleanly. It does not own any gameplay path.
class WireCoreSupervisor final {
public:
    explicit WireCoreSupervisor(QString socketPath);
    ~WireCoreSupervisor();

    WireCoreSupervisor(const WireCoreSupervisor&) = delete;
    WireCoreSupervisor& operator=(const WireCoreSupervisor&) = delete;

    // Start the sidecar process (found at wirecoreBinary) and connect.
    bool start(const QString& wirecoreBinary, QString* error = nullptr);

    // Optional work: enqueue a request frame; returns immediately.
    // Never blocks the caller. Returns false when WireCore is absent.
    bool postRequest(FrameKind kind, const QString& frameId,
                     const QByteArray& payloadJson, QString* error = nullptr);

    // Snapshot health without blocking.
    bool healthy() const;

    void stop();

private:
    QString m_socketPath;
    qint64 m_pid = -1;
    bool m_connected = false;
};

}  // namespace wiremudder

#endif  // WIREMUDDER_BRIDGE_WIRECORE_BRIDGE_H
