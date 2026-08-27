// WireMudder routing profile store (Qt layer, SPEC-006/010).
// Mirrors the wire-routing Rust core semantics for oracle cross-check.
// Explicit user-owned routes, connect-time validation, no silent
// fallback to direct, user-triggered egress verification, and a
// credential-redacted routing audit log (WM-FEAT-0092).
#pragma once

#include <QJsonObject>
#include <QString>
#include <QVector>

namespace wiremudder {

constexpr int ROUTING_SCHEMA_VERSION = 1;

enum class RouteKind {
    Direct,
    System,
    Socks5,
    Socks4a,
    HttpConnect,
    TorLocalSocks,
    SshDynamicForward,
    VpnMetadata,
    InterfaceBinding,  // future, disabled
    VmNetns,           // future, disabled
    SelfHostedRelay,   // future, disabled
};

bool routeKindEnabled(RouteKind k);
const char* routeKindLabel(RouteKind k);

struct RouteProfile {
    QString id;
    QString name;
    RouteKind kind = RouteKind::Direct;
    QString host;
    int port = 0;
    QString username;  // stored locally; never serialized into audit

    static RouteProfile create(const QString& id, const QString& name, RouteKind kind,
                               const QString& host, int port, const QString& username,
                               QString* err);
    bool validate(QString* err) const;
    QJsonObject toJson() const;
    QJsonObject toRedactedJson() const;  // no username field at all
    static bool fromJson(const QJsonObject& obj, RouteProfile* out, QString* err);
};

struct RouteDecision {
    QString routeId;
    RouteKind kind = RouteKind::Direct;
    QString effectiveHost;
    int effectivePort = 0;
    bool requiresCredentials = false;
    bool egressVerified = false;

    QJsonObject toJson() const;
};

struct EgressResult {
    QString routeId;
    bool ok = false;
    QString detail;
};

struct RoutingAuditEntry {
    qint64 atUnix = 0;
    QString routeId;
    RouteKind kind = RouteKind::Direct;
    QString event;
    QJsonObject redactedRoute;
    QString detail;
};

class RoutingStoreQt {
public:
    RoutingStoreQt() = default;

    bool addRoute(const RouteProfile& route, QString* err);
    const RouteProfile* get(const QString& id) const;
    QVector<const RouteProfile*> list() const;
    bool remove(const QString& id, QString* err);
    bool select(const QString& id, QString* err);
    const RouteProfile* selected() const;
    // Connect-time validation: returns a decision or sets err; never
    // silently returns direct (WM-SPEC-006-R06).
    bool decision(RouteDecision* out, QString* err) const;
    bool verifyEgress(const QString& host, int port, EgressResult* out, QString* err);
    const QVector<RoutingAuditEntry>& auditLog() const { return m_audit; }

    bool saveToDir(const QString& dir, QString* err) const;
    bool loadFromDir(const QString& dir, QString* err);

private:
    QVector<RouteProfile> m_routes;
    QString m_selected;
    QVector<RoutingAuditEntry> m_audit;

    const RouteProfile* find(const QString& id) const;
    void appendAudit(const QString& routeId, const QString& event, const QString& detail);
};

}  // namespace wiremudder
