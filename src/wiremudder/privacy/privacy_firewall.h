// WireMudder C++/Qt privacy firewall boundary (SPEC-010, SPEC-022).
//
// Declares the minimal C++ surface of the Privacy Firewall: privacy
// modes, Local Only Lockdown (denial-first egress), consent checks,
// and deterministic redaction. The core logic lives in the Rust
// wire-privacy crate; this header is the Qt-facing adapter surface
// with the same deterministic semantics (cross-validated in the E2E
// milestone).
//
// This header and its implementation are the C++ surface EP-006 owns;
// no inherited source is modified by the privacy modules.

#ifndef WIREMUDDER_PRIVACY_PRIVACY_FIREWALL_H
#define WIREMUDDER_PRIVACY_PRIVACY_FIREWALL_H

#include <QHash>
#include <QString>
#include <QStringList>

namespace wiremudder {

// Privacy modes with exact egress behavior (WM-SPEC-010-R03).
enum class PrivacyMode {
    Disabled,
    LocalOnly,
    LocalPreferred,
    RemoteRedacted,
    RemoteApproved
};

// A user-visible, consent-backed egress override (WM-SPEC-010-R04).
struct OverrideEntry {
    QString overrideId;
    QString category;
    bool userVisible = false;
    QString consentReceiptId;
};

// Denial-first egress control (WM-SPEC-010-R04, WM-SPEC-022-R03).
// Default posture is LocalOnly + lockdown: no remote egress until the
// user visibly overrides with a consent-backed override.
class PrivacyFirewall final {
public:
    PrivacyFirewall();

    // Egress decision. Denied unless the destination is allow-listed
    // and the category is not denied or has a user-visible,
    // consent-backed override.
    bool canEgress(const QString& category, const QString& destination) const;

    // Lawful routing only (WM-SPEC-022-R07): proxy procurement,
    // identity rotation, fingerprint spoofing, account automation,
    // spam, and ban evasion are always denied.
    bool canRoutePurpose(const QString& purpose) const;

    // Deterministic redaction of sensitive material in text.
    QString redact(const QString& text) const;

    // Redact every configured secret value wherever it appears.
    QString redactSecrets(const QString& text) const;

    bool lockdown() const { return m_lockdown; }
    PrivacyMode mode() const { return m_mode; }

    void setMode(PrivacyMode mode);
    void setLockdown(bool enabled);
    void addAllowedDestination(const QString& destination);
    bool addOverride(const OverrideEntry& entry);

    // Consent registry (WM-SPEC-010-R09): scoped, revocable receipts.
    bool grantConsent(const QString& receiptId, const QString& feature,
                      const QString& provider, const QString& dataClass,
                      const QString& profile);
    bool revokeConsent(const QString& receiptId);
    bool isConsented(const QString& receiptId, const QString& feature,
                     const QString& provider, const QString& dataClass,
                     const QString& profile) const;

private:
    PrivacyMode m_mode = PrivacyMode::LocalOnly;
    bool m_lockdown = true;
    QStringList m_allowedDestinations;
    QStringList m_deniedCategories{
        QStringLiteral("ai"),          QStringLiteral("speech"),
        QStringLiteral("asset-generation"), QStringLiteral("telemetry"),
        QStringLiteral("package-download"), QStringLiteral("update-check"),
    };
    QHash<QString, OverrideEntry> m_overrides;
    // consent receipt id -> (feature, provider, dataClass, profile, status)
    QHash<QString, QStringList> m_consent;
};

}  // namespace wiremudder

#endif  // WIREMUDDER_PRIVACY_PRIVACY_FIREWALL_H
