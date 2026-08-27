// WireMudder Package Boundary (EP-010)
//
// Declares the C++ surface for package manifests, permission firewall,
// import gating, and quarantine. Implementations bind to the Rust
// wire-packages core; the boundary keeps Qt/UI concerns out of the core.
#pragma once

#include <QString>
#include <QStringList>
#include <QSet>
#include <QHash>

namespace wiremudder::packages {

// Permission categories (WM-SPEC-008-R04). Default deny.
enum class Permission {
    Filesystem,
    Network,
    Microphone,
    AiEgress,
    Secrets,
    Routing,
    Updater,
    Telemetry,
    Ui,
    CommandSend,
    Memory,
    Renderer,
    Audio
};

inline QString permissionName(Permission p) {
    switch (p) {
    case Permission::Filesystem: return QStringLiteral("filesystem");
    case Permission::Network: return QStringLiteral("network");
    case Permission::Microphone: return QStringLiteral("microphone");
    case Permission::AiEgress: return QStringLiteral("ai_egress");
    case Permission::Secrets: return QStringLiteral("secrets");
    case Permission::Routing: return QStringLiteral("routing");
    case Permission::Updater: return QStringLiteral("updater");
    case Permission::Telemetry: return QStringLiteral("telemetry");
    case Permission::Ui: return QStringLiteral("ui");
    case Permission::CommandSend: return QStringLiteral("command_send");
    case Permission::Memory: return QStringLiteral("memory");
    case Permission::Renderer: return QStringLiteral("renderer");
    case Permission::Audio: return QStringLiteral("audio");
    }
    return QStringLiteral("unknown");
}

inline Permission permissionFromName(const QString& name) {
    static const QHash<QString, Permission> map = {
        {QStringLiteral("filesystem"), Permission::Filesystem},
        {QStringLiteral("network"), Permission::Network},
        {QStringLiteral("microphone"), Permission::Microphone},
        {QStringLiteral("ai_egress"), Permission::AiEgress},
        {QStringLiteral("secrets"), Permission::Secrets},
        {QStringLiteral("routing"), Permission::Routing},
        {QStringLiteral("updater"), Permission::Updater},
        {QStringLiteral("telemetry"), Permission::Telemetry},
        {QStringLiteral("ui"), Permission::Ui},
        {QStringLiteral("command_send"), Permission::CommandSend},
        {QStringLiteral("memory"), Permission::Memory},
        {QStringLiteral("renderer"), Permission::Renderer},
        {QStringLiteral("audio"), Permission::Audio}
    };
    return map.value(name, Permission::Filesystem);
}

// Package manifest (WM-SPEC-008-R03).
struct PackageManifest {
    QString name;
    QString version;
    QString provenance;      // "user_local:author" or "signed:signer"
    QString license;
    QString contentSha256;
    QSet<Permission> requestedPermissions;
    QString updatePolicy;    // "never" | "manual" | "auto"
    QString wiremudderCompat;
    QString mudletCompat;
};

// Firewall decision.
enum class Decision { Granted, Denied, NeedsApproval };

// The permission firewall. Default deny.
class PermissionFirewall {
public:
    PermissionFirewall() = default;

    void grant(const QSet<Permission>& perms) { m_granted.unite(perms); }

    bool isGranted(Permission p) const { return m_granted.contains(p); }

    Decision decide(Permission p) const {
        return m_granted.contains(p) ? Decision::Granted : Decision::Denied;
    }

    // Permissions requested but not yet approved (WM-SPEC-008-R05).
    QSet<Permission> expansion(const QSet<Permission>& requested) const {
        QSet<Permission> out;
        for (Permission p : requested) {
            if (!m_granted.contains(p)) out.insert(p);
        }
        return out;
    }

private:
    QSet<Permission> m_granted;
};

// Quarantine for runaway hooks (WM-SPEC-008-R10).
class Quarantine {
public:
    Quarantine() = default;
    void quarantine(const QString& hookId) { m_quarantined.insert(hookId); }
    bool isQuarantined(const QString& hookId) const { return m_quarantined.contains(hookId); }
    void release(const QString& hookId) { m_quarantined.remove(hookId); }
private:
    QSet<QString> m_quarantined;
};

// Import state (WM-SPEC-008-R06).
enum class ImportState { Disabled, PendingConfirmation, Enabled };

// Content hash verification (WM-SPEC-020-R05).
inline bool verifyContentHash(const QString& expected, const QString& actual) {
    return expected.compare(actual, Qt::CaseInsensitive) == 0;
}

} // namespace wiremudder::packages
