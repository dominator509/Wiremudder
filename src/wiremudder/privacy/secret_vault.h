// WireMudder C++/Qt Secrets Vault boundary (SPEC-010-R06/R07).
//
// Declares the minimal C++ surface of the Secrets Vault. The vault
// protects MUD passwords, provider tokens, routing credentials, SSH
// references, and signing metadata. Storage is OS-backed via QtKeychain
// (the certified backend); until a backend is available the vault uses
// the documented local-only fallback and guarantees leak redaction so
// secret values never enter AI context, logs, or transcripts.
//
// This header is the C++ surface EP-006 owns; the QtKeychain-backed
// implementation arrives in the M3 integration milestone.

#ifndef WIREMUDDER_PRIVACY_SECRET_VAULT_H
#define WIREMUDDER_PRIVACY_SECRET_VAULT_H

#include <QByteArray>
#include <QHash>
#include <QSet>
#include <QString>
#include <QStringList>

namespace wiremudder {

// Secret classes (SPEC-010-R06).
enum class SecretClass {
    MudPassword,
    ProviderToken,
    RoutingCredential,
    SshReference,
    SigningMetadata
};

// Secrets Vault Qt surface. Values are never logged or serialized
// (WM-SPEC-010-R07).
class SecretVaultQt final {
public:
    SecretVaultQt();

    // True when the OS-backed (QtKeychain) backend is usable.
    bool backendAvailable() const;

    // Store a secret; returns false on duplicate/invalid id.
    bool store(const QString& id, SecretClass cls, const QByteArray& value);

    // Retrieve a secret value; empty on not-found.
    QByteArray retrieve(const QString& id) const;

    bool remove(const QString& id);

    QStringList ids() const;

    // Replace every stored secret value in text with [REDACTED:class].
    QString redactLeak(const QString& text) const;

private:
    bool m_osBackend = false;
    QHash<QString, QByteArray> m_memory;   // local-only fallback store
    QSet<QString> m_ids;                   // index of stored secret ids
};

}  // namespace wiremudder

#endif  // WIREMUDDER_PRIVACY_SECRET_VAULT_H
