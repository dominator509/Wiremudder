// WireMudder EP-006 M3 integration/E2E harness.
//
// Drives the REAL C++ PrivacyFirewall and SecretVaultQt (QtKeychain)
// implementations. Subcommands:
//   firewall            firewall invariants: lockdown, overrides,
//                       routing, redaction
//   vault               secrets vault: store/retrieve/remove/redactLeak
//   e2e                 print the policy matrix in the canonical
//                       format for cross-validation with the Rust core

#include "src/wiremudder/privacy/privacy_firewall.h"
#include "src/wiremudder/privacy/secret_vault.h"

#include <QCoreApplication>
#include <QStringList>

#include <cstdio>
#include <cstdlib>

using wiremudder::OverrideEntry;
using wiremudder::PrivacyFirewall;
using wiremudder::PrivacyMode;
using wiremudder::SecretClass;
using wiremudder::SecretVaultQt;

namespace {

bool g_fail = false;

void fail(const char* reason) {
    g_fail = true;
    fprintf(stderr, "HARNESS FAIL: %s\n", reason);
}

bool runFirewall() {
    PrivacyFirewall fw;

    // 1. Default posture: denial-first.
    if (fw.canEgress("ai", "https://api.example.com")) fail("lockdown must deny by default");
    if (fw.canRoutePurpose("proxy-procurement")) fail("proxy procurement must be denied");
    if (!fw.canRoutePurpose("translation")) fail("lawful routing purpose denied");

    // 2. Allow-list alone is not enough for a denied category.
    fw.addAllowedDestination("https://api.example.com");
    if (fw.canEgress("ai", "https://api.example.com")) fail("ai must stay denied without override");

    // 3. Override requires user visibility + consent reference.
    OverrideEntry hidden;
    hidden.overrideId = "ovr-123456";
    hidden.category = "ai";
    hidden.userVisible = false;
    hidden.consentReceiptId = "receipt-1234567890";
    if (fw.addOverride(hidden)) fail("non-visible override accepted");

    OverrideEntry valid;
    valid.overrideId = "ovr-123456";
    valid.category = "ai";
    valid.userVisible = true;
    valid.consentReceiptId = "receipt-1234567890";
    if (!fw.addOverride(valid)) fail("valid override rejected");

    // 4. With the override, the allow-listed destination passes.
    if (!fw.canEgress("ai", "https://api.example.com")) fail("override did not unlock egress");
    if (fw.canEgress("ai", "https://evil.example.com")) fail("non-allow-listed destination passed");
    if (fw.canEgress("speech", "https://api.example.com")) fail("speech denied category passed without override");

    // 5. Consent scoping + revocation.
    if (!fw.grantConsent("receipt-1234567890", "ai", "local", "transcript", "oracle"))
        fail("grantConsent failed");
    if (!fw.isConsented("receipt-1234567890", "ai", "local", "transcript", "oracle"))
        fail("consent not granted");
    if (fw.isConsented("receipt-1234567890", "speech", "local", "transcript", "oracle"))
        fail("consent not scoped to feature");
    if (!fw.revokeConsent("receipt-1234567890")) fail("revoke failed");
    if (fw.isConsented("receipt-1234567890", "ai", "local", "transcript", "oracle"))
        fail("revoked consent still granted");

    // 6. Deterministic redaction.
    const QString secret = QStringLiteral("key sk-abcdefghijklmnop here");
    const QString r1 = fw.redact(secret);
    const QString r2 = fw.redact(secret);
    if (r1 != r2) fail("redaction not deterministic");
    if (r1.contains(QStringLiteral("sk-abcdefghijklmnop"))) fail("secret survived redaction");

    if (g_fail) return false;
    printf("integration privacy-firewall: ok\n");
    return true;
}

bool runVault() {
    SecretVaultQt vault;

    if (!vault.store("mud-main", SecretClass::MudPassword, QByteArray("hunter2")))
        fail("store mud-main failed");
    if (!vault.store("prov-tok", SecretClass::ProviderToken, QByteArray("tok-1234")))
        fail("store prov-tok failed");
    if (vault.store("mud-main", SecretClass::MudPassword, QByteArray("other")))
        fail("duplicate store accepted");

    if (vault.retrieve("mud-main") != QByteArray("hunter2")) fail("retrieve mud-main wrong");
    if (vault.retrieve("prov-tok") != QByteArray("tok-1234")) fail("retrieve prov-tok wrong");
    if (!vault.retrieve("missing-id").isEmpty()) fail("missing id returned data");

    if (vault.ids() != QStringList{QStringLiteral("mud-main"), QStringLiteral("prov-tok")})
        fail("ids mismatch");

    const QString text = QStringLiteral("login hunter2 then send tok-1234 via hunter2");
    const QString redacted = vault.redactLeak(text);
    if (redacted.contains(QStringLiteral("hunter2")) || redacted.contains(QStringLiteral("tok-1234")))
        fail("leak redaction failed");
    if (redacted != QStringLiteral("login [REDACTED:secret] then send [REDACTED:secret] via [REDACTED:secret]"))
        fail("leak redaction output wrong");

    if (!vault.remove("mud-main")) fail("remove failed");
    if (!vault.retrieve("mud-main").isEmpty()) fail("removed secret still retrievable");

    printf("backend_available=%d\n", vault.backendAvailable() ? 1 : 0);
    if (g_fail) return false;
    printf("integration secrets-vault: ok\n");
    return true;
}

void printMatrix() {
    PrivacyFirewall fw;
    fw.addAllowedDestination(QStringLiteral("https://api.example.com"));
    OverrideEntry valid;
    valid.overrideId = QStringLiteral("ovr-123456");
    valid.category = QStringLiteral("ai");
    valid.userVisible = true;
    valid.consentReceiptId = QStringLiteral("receipt-1234567890");
    fw.addOverride(valid);

    struct Case { const char* cat; const char* dst; };
    const Case cases[] = {
        {"ai", "https://api.example.com"},
        {"ai", "https://evil.example.com"},
        {"speech", "https://api.example.com"},
        {"telemetry", "https://api.example.com"},
    };
    for (const Case& c : cases) {
        printf("canEgress|%s|%s|%d\n", c.cat, c.dst,
               fw.canEgress(QString::fromUtf8(c.cat), QString::fromUtf8(c.dst)) ? 1 : 0);
    }
    for (const char* purpose : {"proxy-procurement", "translation"}) {
        printf("canRoute|%s|%d\n", purpose,
               fw.canRoutePurpose(QString::fromUtf8(purpose)) ? 1 : 0);
    }
}

}  // namespace

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    if (argc < 2) {
        fprintf(stderr, "usage: %s firewall|vault|e2e\n", argv[0]);
        return 2;
    }
    const QString cmd = QString::fromLocal8Bit(argv[1]);
    bool ok = false;
    if (cmd == "firewall") {
        ok = runFirewall();
    } else if (cmd == "vault") {
        ok = runVault();
    } else if (cmd == "e2e") {
        printMatrix();
        return 0;
    } else {
        fprintf(stderr, "unknown subcommand: %s\n", qPrintable(cmd));
        return 2;
    }
    return ok ? 0 : 1;
}
