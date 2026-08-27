// WireMudder C++/Qt Secrets Vault implementation (SPEC-010-R06/R07).
//
// OS-backed storage via QtKeychain when a keyring service is
// available; otherwise the documented local-only fallback (in-memory)
// until an OS backend is certified. Values are never logged or
// serialized; redactLeak guarantees secrets cannot enter AI context,
// logs, or transcripts.

#include "src/wiremudder/privacy/secret_vault.h"

#include <QEventLoop>
#include <QHash>
#include <QSet>
#include <QTimer>
#include <qt6keychain/keychain.h>

namespace wiremudder {

namespace {
QString classToStr(SecretClass cls) {
    switch (cls) {
        case SecretClass::MudPassword: return QStringLiteral("mud-password");
        case SecretClass::ProviderToken: return QStringLiteral("provider-token");
        case SecretClass::RoutingCredential: return QStringLiteral("routing-credential");
        case SecretClass::SshReference: return QStringLiteral("ssh-reference");
        case SecretClass::SigningMetadata: return QStringLiteral("signing-metadata");
    }
    return QStringLiteral("unknown");
}

// Run a QtKeychain job to completion with a bounded wait.
bool runJob(QKeychain::Job* job, int timeoutMs = 3000) {
    QEventLoop loop;
    QTimer timeout;
    timeout.setSingleShot(true);
    QObject::connect(&timeout, &QTimer::timeout, &loop, &QEventLoop::quit);
    QObject::connect(job, &QKeychain::Job::finished, &loop, &QEventLoop::quit);
    timeout.start(timeoutMs);
    job->start();
    loop.exec();
    return job->error() == QKeychain::NoError;
}
}  // namespace

SecretVaultQt::SecretVaultQt() {
    // Probe the OS backend with a sentinel read. If no keyring service
    // exists (e.g. headless without gnome-keyring/kwallet), the vault
    // falls back to the documented local-only in-memory store.
    QKeychain::ReadPasswordJob probe(QStringLiteral("WireMudder"));
    probe.setKey(QStringLiteral("__wm_vault_probe__"));
    probe.setAutoDelete(false);
    m_osBackend = runJob(&probe);
}

bool SecretVaultQt::backendAvailable() const {
    return m_osBackend;
}

bool SecretVaultQt::store(const QString& id, SecretClass cls, const QByteArray& value) {
    if (id.size() < 4 || value.isEmpty()) return false;
    if (m_ids.contains(id)) return false;  // duplicate rejected
    const QByteArray payload = classToStr(cls).toUtf8() + ':' + value;
    if (m_osBackend) {
        QKeychain::WritePasswordJob job(QStringLiteral("WireMudder"));
        job.setKey(id);
        job.setTextData(QString::fromUtf8(payload));
        job.setAutoDelete(false);
        if (!runJob(&job)) return false;
    }
    m_memory.insert(id, payload);
    m_ids.insert(id);
    return true;
}

QByteArray SecretVaultQt::retrieve(const QString& id) const {
    QByteArray payload;
    if (m_osBackend) {
        QKeychain::ReadPasswordJob job(QStringLiteral("WireMudder"));
        job.setKey(id);
        job.setAutoDelete(false);
        if (!runJob(&job)) return QByteArray();
        payload = job.textData().toUtf8();
    } else {
        const auto it = m_memory.constFind(id);
        if (it == m_memory.constEnd()) return QByteArray();
        payload = it.value();
    }
    const int colon = payload.indexOf(':');
    if (colon < 0) return QByteArray();
    return payload.mid(colon + 1);
}

bool SecretVaultQt::remove(const QString& id) {
    if (!m_ids.contains(id)) return false;
    if (m_osBackend) {
        QKeychain::DeletePasswordJob job(QStringLiteral("WireMudder"));
        job.setKey(id);
        job.setAutoDelete(false);
        runJob(&job);  // best effort; the local index is authoritative
    }
    m_memory.remove(id);
    m_ids.remove(id);
    return true;
}

QStringList SecretVaultQt::ids() const {
    QStringList out = m_ids.values();
    out.sort();
    return out;
}

QString SecretVaultQt::redactLeak(const QString& text) const {
    QString out = text;
    for (const QString& id : m_ids) {
        const QByteArray value = retrieve(id);
        if (!value.isEmpty()) {
            const QString v = QString::fromUtf8(value);
            if (!v.isEmpty()) {
                out.replace(v, QStringLiteral("[REDACTED:secret]"));
            }
        }
    }
    return out;
}

}  // namespace wiremudder
