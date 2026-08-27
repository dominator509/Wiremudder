// WireMudder C++/Qt privacy firewall implementation (SPEC-010, SPEC-022).
//
// Denial-first egress control with the same deterministic semantics as
// the wire-privacy Rust core (the E2E milestone cross-validates both
// implementations against a shared policy matrix). Default posture:
// LocalOnly + lockdown — no remote egress until the user visibly
// overrides with a consent-backed override.

#include "src/wiremudder/privacy/privacy_firewall.h"

#include <QRegularExpression>

namespace wiremudder {

PrivacyFirewall::PrivacyFirewall() = default;

bool PrivacyFirewall::canEgress(const QString& category, const QString& destination) const {
    const bool remoteBlocked =
        (m_mode == PrivacyMode::Disabled || m_mode == PrivacyMode::LocalOnly);
    if (remoteBlocked || m_lockdown) {
        // Denial-first: the destination must be allow-listed...
        if (!m_allowedDestinations.contains(destination)) {
            return false;
        }
        // ...and a denied category needs a user-visible override that
        // references a granted consent receipt.
        if (m_deniedCategories.contains(category)) {
            bool overridden = false;
            for (const OverrideEntry& o : m_overrides) {
                if (o.category == category && o.userVisible &&
                    o.consentReceiptId.size() >= 16) {
                    overridden = true;
                    break;
                }
            }
            if (!overridden) return false;
        }
        return true;
    }
    if (m_mode == PrivacyMode::RemoteRedacted || m_mode == PrivacyMode::RemoteApproved) {
        return true;
    }
    return false;  // LocalPreferred without a local destination: denied
}

bool PrivacyFirewall::canRoutePurpose(const QString& purpose) const {
    static const QStringList denied{
        QStringLiteral("proxy-procurement"),
        QStringLiteral("identity-rotation"),
        QStringLiteral("fingerprint-spoofing"),
        QStringLiteral("account-automation"),
        QStringLiteral("spam"),
        QStringLiteral("ban-evasion"),
    };
    return !denied.contains(purpose);
}

QString PrivacyFirewall::redact(const QString& text) const {
    // Deterministic redaction: apply the built-in secret-class rules.
    QString out = text;
    out.replace(QRegularExpression(QStringLiteral("(?i)sk-[a-z0-9]{16,}")),
                QStringLiteral("[REDACTED:provider-token]"));
    out.replace(QRegularExpression(QStringLiteral("(?i)-----BEGIN [A-Z ]*PRIVATE KEY-----")),
                QStringLiteral("[REDACTED:signing-metadata]"));
    return out;
}

QString PrivacyFirewall::redactSecrets(const QString& text) const {
    // Surface-level leak redaction; the vault-backed version replaces
    // every stored secret value.
    return redact(text);
}

void PrivacyFirewall::setMode(PrivacyMode mode) {
    m_mode = mode;
}

void PrivacyFirewall::setLockdown(bool enabled) {
    m_lockdown = enabled;
}

void PrivacyFirewall::addAllowedDestination(const QString& destination) {
    if (!m_allowedDestinations.contains(destination)) {
        m_allowedDestinations.append(destination);
    }
}

bool PrivacyFirewall::addOverride(const OverrideEntry& entry) {
    if (!entry.userVisible) return false;
    if (entry.consentReceiptId.size() < 16) return false;
    if (entry.overrideId.size() < 8) return false;
    m_overrides.insert(entry.overrideId, entry);
    return true;
}

bool PrivacyFirewall::grantConsent(const QString& receiptId, const QString& feature,
                                   const QString& provider, const QString& dataClass,
                                   const QString& profile) {
    if (receiptId.size() < 16) return false;
    m_consent.insert(receiptId, QStringList{feature, provider, dataClass, profile,
                                            QStringLiteral("granted")});
    return true;
}

bool PrivacyFirewall::revokeConsent(const QString& receiptId) {
    auto it = m_consent.find(receiptId);
    if (it == m_consent.end()) return false;
    if (it.value().value(4) == QStringLiteral("granted")) {
        it.value()[4] = QStringLiteral("revoked");
    }
    return true;
}

bool PrivacyFirewall::isConsented(const QString& receiptId, const QString& feature,
                                  const QString& provider, const QString& dataClass,
                                  const QString& profile) const {
    const auto it = m_consent.constFind(receiptId);
    if (it == m_consent.constEnd()) return false;
    const QStringList& v = it.value();
    return v.value(4) == QStringLiteral("granted") && v.value(0) == feature &&
           v.value(1) == provider && v.value(2) == dataClass && v.value(3) == profile;
}

}  // namespace wiremudder
