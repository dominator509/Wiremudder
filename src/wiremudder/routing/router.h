// WireMudder router (Qt layer, SPEC-006).
// Converts a validated RouteDecision into a real QNetworkProxy that the
// inherited connection code (Host::getConnectionProxy / cTelnet socket
// assignment) can consume unchanged, and performs connect-time
// validation on a real QTcpSocket. A selected route that is missing or
// fails BLOCKS; it never silently falls back to direct networking
// (WM-SPEC-006-R06).
#pragma once

#include <QNetworkProxy>
#include <QTcpSocket>

#include "route_profile_store.h"

namespace wiremudder {

class RouterQt {
public:
    // Map a validated decision to a QNetworkProxy. Direct/system routes
    // yield QNetworkProxy::NoProxy (the explicit user choice).
    static QNetworkProxy toNetworkProxy(const RouteDecision& d);

    // Connect-time validation: apply the decision to a real socket and
    // connect. Returns false (and sets err) when the route is missing,
    // invalid, or the connection fails -- the caller must block or
    // prompt, never fall back to direct (WM-SPEC-006-R06).
    static bool connectViaDecision(QTcpSocket* socket, const RouteDecision& d,
                                   const QString& targetHost, quint16 targetPort,
                                   int timeoutMs, QString* err);
};

}  // namespace wiremudder
