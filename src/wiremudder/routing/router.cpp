// WireMudder router (Qt layer).
#include "router.h"

#include <QTcpSocket>

namespace wiremudder {

QNetworkProxy RouterQt::toNetworkProxy(const RouteDecision& d)
{
    switch (d.kind) {
    case RouteKind::Direct:
    case RouteKind::System:
        // Explicit user choice of direct/system networking.
        return QNetworkProxy(QNetworkProxy::NoProxy);
    case RouteKind::Socks5:
    case RouteKind::TorLocalSocks: {
        QNetworkProxy p(QNetworkProxy::Socks5Proxy);
        p.setHostName(d.effectiveHost);
        p.setPort(quint16(d.effectivePort));
        return p;
    }
    case RouteKind::Socks4a: {
        QNetworkProxy p(QNetworkProxy::Socks5Proxy);
        // Qt has no SOCKS4a type; SOCKS5 negotiation is used for
        // the local relay endpoint. The decision still records the
        // declared kind for audit and validation.
        p.setHostName(d.effectiveHost);
        p.setPort(quint16(d.effectivePort));
        return p;
    }
    case RouteKind::HttpConnect: {
        QNetworkProxy p(QNetworkProxy::HttpProxy);
        p.setHostName(d.effectiveHost);
        p.setPort(quint16(d.effectivePort));
        return p;
    }
    case RouteKind::SshDynamicForward: {
        // SSH dynamic forward exposes a local SOCKS5 endpoint.
        QNetworkProxy p(QNetworkProxy::Socks5Proxy);
        p.setHostName(d.effectiveHost);
        p.setPort(quint16(d.effectivePort));
        return p;
    }
    case RouteKind::VpnMetadata:
    case RouteKind::InterfaceBinding:
    case RouteKind::VmNetns:
    case RouteKind::SelfHostedRelay:
        // Metadata-only or future routes have no socket-level proxy;
        // connection must not proceed through them (R06 blocks).
        return QNetworkProxy(QNetworkProxy::NoProxy);
    }
    return QNetworkProxy(QNetworkProxy::NoProxy);
}

bool RouterQt::connectViaDecision(QTcpSocket* socket, const RouteDecision& d, const QString& targetHost, quint16 targetPort, int timeoutMs, QString* err)
{
    // Connect-time validation: the decision must be present and valid.
    if (d.routeId.isEmpty()) {
        if (err)
            *err = "no route selected; blocking connect";
        return false;
    }
    if (!routeKindEnabled(d.kind)) {
        if (err)
            *err = QString("route kind disabled: %1").arg(routeKindLabel(d.kind));
        return false;
    }
    // Direct/system is only used when the user explicitly selected it.
    const bool explicitDirect = (d.kind == RouteKind::Direct || d.kind == RouteKind::System);
    if (explicitDirect) {
        socket->setProxy(QNetworkProxy::NoProxy);
    } else {
        socket->setProxy(toNetworkProxy(d));
    }
    socket->connectToHost(targetHost, targetPort);
    if (!socket->waitForConnected(timeoutMs)) {
        if (err) {
            *err = QString("route %1 connect failed: %2").arg(QString::fromUtf8(routeKindLabel(d.kind)), socket->errorString());
        }
        return false;
    }
    if (err)
        *err = QString();
    return true;
}

} // namespace wiremudder
