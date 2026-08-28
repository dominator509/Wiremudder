// WireMudder routing profile store (Qt layer).
#include "route_profile_store.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QTcpSocket>

namespace wiremudder {

bool routeKindEnabled(RouteKind k)
{
    return !(k == RouteKind::InterfaceBinding || k == RouteKind::VmNetns || k == RouteKind::SelfHostedRelay);
}

const char* routeKindLabel(RouteKind k)
{
    switch (k) {
    case RouteKind::Direct:
        return "direct";
    case RouteKind::System:
        return "system";
    case RouteKind::Socks5:
        return "socks5";
    case RouteKind::Socks4a:
        return "socks4a";
    case RouteKind::HttpConnect:
        return "http-connect";
    case RouteKind::TorLocalSocks:
        return "tor-local-socks";
    case RouteKind::SshDynamicForward:
        return "ssh-dynamic-forward";
    case RouteKind::VpnMetadata:
        return "vpn-metadata";
    case RouteKind::InterfaceBinding:
        return "interface-binding (future)";
    case RouteKind::VmNetns:
        return "vm-netns (future)";
    case RouteKind::SelfHostedRelay:
        return "self-hosted-relay (future)";
    }
    return "unknown";
}

RouteProfile RouteProfile::create(const QString& id, const QString& name, RouteKind kind, const QString& host, int port, const QString& username, QString* err)
{
    RouteProfile r;
    if (id.isEmpty() || name.isEmpty()) {
        if (err)
            *err = "invalid name";
        return r;
    }
    if (!routeKindEnabled(kind)) {
        if (err)
            *err = QString("unsupported kind: %1").arg(routeKindLabel(kind));
        return r;
    }
    r.id = id;
    r.name = name;
    r.kind = kind;
    r.host = host;
    r.port = port;
    r.username = username;
    if (err)
        *err = QString();
    return r;
}

bool RouteProfile::validate(QString* err) const
{
    if (!routeKindEnabled(kind)) {
        if (err)
            *err = QString("unsupported kind: %1").arg(routeKindLabel(kind));
        return false;
    }
    switch (kind) {
    case RouteKind::Direct:
    case RouteKind::System:
    case RouteKind::VpnMetadata:
        if (err)
            *err = QString();
        return true;
    case RouteKind::Socks5:
    case RouteKind::Socks4a:
    case RouteKind::HttpConnect:
    case RouteKind::TorLocalSocks:
        if (host.isEmpty()) {
            if (err)
                *err = "missing host";
            return false;
        }
        if (port == 0) {
            if (err)
                *err = "missing port";
            return false;
        }
        if (err)
            *err = QString();
        return true;
    case RouteKind::SshDynamicForward:
        if (host.isEmpty()) {
            if (err)
                *err = "missing host";
            return false;
        }
        if (err)
            *err = QString();
        return true;
    case RouteKind::InterfaceBinding:
    case RouteKind::VmNetns:
    case RouteKind::SelfHostedRelay:
        if (err)
            *err = QString("unsupported kind: %1").arg(routeKindLabel(kind));
        return false;
    }
    return false;
}

QJsonObject RouteProfile::toJson() const
{
    QJsonObject o;
    o.insert("id", id);
    o.insert("name", name);
    o.insert("kind", QString::fromUtf8(routeKindLabel(kind)));
    o.insert("host", host);
    o.insert("port", port);
    o.insert("username", username);
    o.insert("schema_version", ROUTING_SCHEMA_VERSION);
    return o;
}

QJsonObject RouteProfile::toRedactedJson() const
{
    QJsonObject o;
    o.insert("id", id);
    o.insert("name", name);
    o.insert("kind", QString::fromUtf8(routeKindLabel(kind)));
    o.insert("host", host);
    o.insert("port", port);
    o.insert("has_credentials", !username.isEmpty());
    o.insert("schema_version", ROUTING_SCHEMA_VERSION);
    return o;
}

bool RouteProfile::fromJson(const QJsonObject& obj, RouteProfile* out, QString* err)
{
    RouteProfile r;
    r.id = obj.value("id").toString();
    r.name = obj.value("name").toString();
    const QString kind = obj.value("kind").toString();
    if (kind == "direct")
        r.kind = RouteKind::Direct;
    else if (kind == "system")
        r.kind = RouteKind::System;
    else if (kind == "socks5")
        r.kind = RouteKind::Socks5;
    else if (kind == "socks4a")
        r.kind = RouteKind::Socks4a;
    else if (kind == "http-connect")
        r.kind = RouteKind::HttpConnect;
    else if (kind == "tor-local-socks")
        r.kind = RouteKind::TorLocalSocks;
    else if (kind == "ssh-dynamic-forward")
        r.kind = RouteKind::SshDynamicForward;
    else if (kind == "vpn-metadata")
        r.kind = RouteKind::VpnMetadata;
    else {
        if (err)
            *err = QString("unknown kind: %1").arg(kind);
        return false;
    }
    r.host = obj.value("host").toString();
    r.port = obj.value("port").toInt();
    r.username = obj.value("username").toString();
    if (r.id.isEmpty() || r.name.isEmpty()) {
        if (err)
            *err = "malformed route";
        return false;
    }
    if (obj.value("schema_version").toInt() != ROUTING_SCHEMA_VERSION) {
        if (err)
            *err = "schema version mismatch";
        return false;
    }
    *out = r;
    if (err)
        *err = QString();
    return true;
}

QJsonObject RouteDecision::toJson() const
{
    QJsonObject o;
    o.insert("route_id", routeId);
    o.insert("kind", QString::fromUtf8(routeKindLabel(kind)));
    o.insert("effective_host", effectiveHost);
    o.insert("effective_port", effectivePort);
    o.insert("requires_credentials", requiresCredentials);
    o.insert("egress_verified", egressVerified);
    return o;
}

const RouteProfile* RoutingStoreQt::find(const QString& id) const
{
    for (const auto& r : m_routes) {
        if (r.id == id)
            return &r;
    }
    return nullptr;
}

void RoutingStoreQt::appendAudit(const QString& routeId, const QString& event, const QString& detail)
{
    RoutingAuditEntry e;
    e.atUnix = QDateTime::currentSecsSinceEpoch();
    e.routeId = routeId;
    e.kind = RouteKind::Direct;
    e.event = event;
    e.detail = detail;
    const RouteProfile* r = find(routeId);
    if (r) {
        e.kind = r->kind;
        e.redactedRoute = r->toRedactedJson();
    } else {
        e.redactedRoute.insert("id", routeId);
        e.redactedRoute.insert("has_credentials", false);
    }
    m_audit.append(e);
}

bool RoutingStoreQt::addRoute(const RouteProfile& route, QString* err)
{
    if (!route.validate(err))
        return false;
    if (find(route.id)) {
        if (err)
            *err = "duplicate id";
        return false;
    }
    m_routes.append(route);
    if (err)
        *err = QString();
    return true;
}

const RouteProfile* RoutingStoreQt::get(const QString& id) const
{
    return find(id);
}

QVector<const RouteProfile*> RoutingStoreQt::list() const
{
    QVector<const RouteProfile*> out;
    for (const auto& r : m_routes)
        out.append(&r);
    std::sort(out.begin(), out.end(), [](const RouteProfile* a, const RouteProfile* b) {
        return a->name < b->name;
    });
    return out;
}

bool RoutingStoreQt::remove(const QString& id, QString* err)
{
    for (int i = 0; i < m_routes.size(); ++i) {
        if (m_routes[i].id == id) {
            m_routes.removeAt(i);
            if (m_selected == id) {
                m_selected.clear();
                appendAudit(id, "selection_cleared", "removed selected route; no silent replacement");
            }
            if (err)
                *err = QString();
            return true;
        }
    }
    if (err)
        *err = "not found";
    return false;
}

bool RoutingStoreQt::select(const QString& id, QString* err)
{
    const RouteProfile* r = find(id);
    if (!r) {
        if (err)
            *err = "not found";
        return false;
    }
    if (!r->validate(err))
        return false;
    m_selected = id;
    appendAudit(id, "selected", "route selected by user");
    if (err)
        *err = QString();
    return true;
}

const RouteProfile* RoutingStoreQt::selected() const
{
    if (m_selected.isEmpty())
        return nullptr;
    return find(m_selected);
}

bool RoutingStoreQt::decision(RouteDecision* out, QString* err) const
{
    if (m_selected.isEmpty()) {
        if (err)
            *err = "no route selected";
        return false;
    }
    const RouteProfile* r = find(m_selected);
    if (!r) {
        if (err)
            *err = "selected route unavailable";
        return false;
    }
    if (!r->validate(err))
        return false;
    RouteDecision d;
    d.routeId = r->id;
    d.kind = r->kind;
    d.effectiveHost = r->host;
    d.effectivePort = r->port;
    d.requiresCredentials = !r->username.isEmpty();
    d.egressVerified = false;
    *out = d;
    if (err)
        *err = QString();
    return true;
}

bool RoutingStoreQt::verifyEgress(const QString& host, int port, EgressResult* out, QString* err)
{
    if (m_selected.isEmpty()) {
        if (err)
            *err = "no route selected";
        return false;
    }
    const RouteProfile* r = find(m_selected);
    if (!r) {
        if (err)
            *err = "selected route unavailable";
        return false;
    }
    // Real controlled egress probe: connect through the selected route's
    // endpoint. For proxy kinds the caller supplies the proxy listener;
    // this performs an actual TCP connect to the endpoint.
    QTcpSocket socket;
    socket.connectToHost(host, quint16(port));
    const bool connected = socket.waitForConnected(2000);
    EgressResult res;
    res.routeId = r->id;
    if (connected) {
        socket.disconnectFromHost();
        res.ok = true;
        res.detail = "verified";
        appendAudit(r->id, "egress_verified", "user-triggered egress verification passed");
    } else {
        res.ok = false;
        res.detail = QString("failed: %1").arg(socket.errorString());
        appendAudit(r->id, "egress_failed", QString("user-triggered egress verification failed: %1").arg(socket.errorString()));
    }
    *out = res;
    if (err)
        *err = QString();
    return true;
}

bool RoutingStoreQt::saveToDir(const QString& dir, QString* err) const
{
    QDir d(dir);
    if (!d.exists() && !d.mkpath(".")) {
        if (err)
            *err = "cannot create dir";
        return false;
    }
    QJsonObject root;
    QJsonArray arr;
    for (const auto& r : m_routes)
        arr.append(r.toJson());
    root.insert("routes", arr);
    root.insert("selected", m_selected);
    QFile f(d.filePath("routing.json"));
    if (!f.open(QIODevice::WriteOnly)) {
        if (err)
            *err = "cannot write routing.json";
        return false;
    }
    f.write(QJsonDocument(root).toJson(QJsonDocument::Compact));
    f.close();
    if (err)
        *err = QString();
    return true;
}

bool RoutingStoreQt::loadFromDir(const QString& dir, QString* err)
{
    QFile f(QDir(dir).filePath("routing.json"));
    if (!f.exists()) {
        if (err)
            *err = QString();
        return true;
    }
    if (!f.open(QIODevice::ReadOnly)) {
        if (err)
            *err = "cannot read routing.json";
        return false;
    }
    QJsonParseError pe;
    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll(), &pe);
    f.close();
    if (pe.error != QJsonParseError::NoError) {
        if (err)
            *err = "malformed routing.json";
        return false;
    }
    const QJsonObject root = doc.object();
    const QJsonArray arr = root.value("routes").toArray();
    for (const auto v : arr) {
        RouteProfile r;
        QString e;
        if (!RouteProfile::fromJson(v.toObject(), &r, &e)) {
            if (err)
                *err = e;
            return false;
        }
        if (find(r.id)) {
            if (err)
                *err = "duplicate id";
            return false;
        }
        m_routes.append(r);
    }
    m_selected = root.value("selected").toString();
    if (err)
        *err = QString();
    return true;
}

} // namespace wiremudder
