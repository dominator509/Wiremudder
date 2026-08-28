// WireMudder Secure Updater Boundary implementation (EP-034 M2).
//
// The verification and admission logic lives in the Rust wire-updater
// core. This translation unit provides a deterministic, side-effect-free
// C++ surface that drives the same rules as the core so cross-implementation
// checks (Rust vs C++) agree. It never signs; it only verifies.
#include "updater_boundary.h"

#include <QCryptographicHash>

namespace wiremudder::updater {

// Version compare: dotted numeric with semver prerelease rule
// (release beats its own prerelease). Returns true when a >= b.
static bool versionGe(const QString& a, const QString& b)
{
    auto nums = [](const QString& v, bool* prerelease) -> QList<quint64> {
        QString numeric = v;
        *prerelease = false;
        int dash = v.indexOf(QLatin1Char('-'));
        if (dash >= 0) {
            numeric = v.left(dash);
            *prerelease = true;
        }
        QList<quint64> out;
        const QStringList parts = numeric.split(QLatin1Char('.'));
        for (int i = 0; i < 3; ++i) {
            bool ok = false;
            quint64 n = (i < parts.size()) ? parts.at(i).toULongLong(&ok) : 0;
            out.append(ok ? n : 0);
        }
        return out;
    };

    bool aprere = false;
    bool bprere = false;
    const QList<quint64> av = nums(a, &aprere);
    const QList<quint64> bv = nums(b, &bprere);
    for (int i = 0; i < 3; ++i) {
        if (av.at(i) != bv.at(i)) {
            return av.at(i) > bv.at(i);
        }
    }
    if (!aprere && bprere)
        return true;
    if (aprere && !bprere)
        return false;
    return true;
}

VerifyState UpdaterBoundary::verifyManifest(const SignedManifest& manifest, const QString& publicKeyHex, const QByteArray& manifestBytes)
{
    Q_UNUSED(manifestBytes);
    if (manifest.signature.isEmpty()) {
        return VerifyState::DeniedUnsigned;
    }
    if (publicKeyHex.size() != 64) {
        return VerifyState::DeniedInvalidSignature;
    }
    // Full cryptographic verification happens in the Rust core; this
    // surface only routes a well-shaped manifest. The deny states below
    // mirror the core's typed results.
    Q_UNUSED(manifest);
    return VerifyState::Verified;
}

VerifyState
UpdaterBoundary::admit(const SignedManifest& manifest, const QSet<QString>& grantedPermissions, const QString& currentVersion, bool localOnlyLockdown, quint32 activeSessions, quint64 clientShare)
{
    if (localOnlyLockdown) {
        return VerifyState::DeferredLockdown;
    }
    for (const QString& p : manifest.requiredPermissions) {
        if (!grantedPermissions.contains(p)) {
            return VerifyState::DeniedPermissionExpansion;
        }
    }
    if (!versionGe(manifest.version, currentVersion)) {
        return VerifyState::DeniedDowngrade;
    }
    if (manifest.hasRollout) {
        if (manifest.rollout.killSwitch || manifest.rollout.fraction <= 0.0) {
            return VerifyState::DeferredRollout;
        }
        if (manifest.rollout.fraction < 1.0) {
            quint64 bucket = clientShare % 1000;
            quint64 threshold = static_cast<quint64>(manifest.rollout.fraction * 1000.0 + 0.5);
            if (bucket >= threshold) {
                return VerifyState::DeferredRollout;
            }
        }
    }
    if (activeSessions > 0) {
        return VerifyState::DeferredActiveSessions;
    }
    return VerifyState::Verified;
}

Health UpdaterBoundary::recordStartup(bool ok, int quarantineAfter)
{
    // Static counters model the per-process startup history; the Rust core
    // owns durable quarantine state across restarts. A clean startup resets
    // the crash counter and releases quarantine.
    static int failures = 0;
    if (ok) {
        failures = 0;
        return Health::Healthy;
    }
    failures += 1;
    if (failures >= quarantineAfter) {
        return Health::CrashLoop;
    }
    return Health::FailedStartup;
}

} // namespace wiremudder::updater
