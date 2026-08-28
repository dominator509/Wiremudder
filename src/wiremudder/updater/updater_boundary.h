// WireMudder Secure Updater, Package Registry, and Rollback Boundary
// (EP-034 M2)
//
// Model-side Qt boundary for the secure updater (SPEC-020, SPEC-010,
// SPEC-022, SPEC-025; WM-SPEC-020-R04/R06/R10, WM-SPEC-028-R04/R08).
// The boundary declares the C++ surface for signed update verification,
// channel and lane policy, staged rollout, permission-expansion rejection,
// migration planning, active-session deferral, quarantine, and rollback
// guidance. Implementations bind to the Rust wire-updater core; the
// boundary keeps Qt/UI concerns out of the core. Signing keys never enter
// this boundary: it verifies against a supplied public key and never signs.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded,
// Canceled, Unavailable, Error. Update failures never block manual text
// gameplay; the terminal remains authoritative (SPEC-020-R08).
#pragma once

#include <QString>
#include <QStringList>
#include <QSet>

namespace wiremudder::updater {

// Release channels (SPEC-020-R01).
enum class Channel {
    Development,
    Canary,
    Beta,
    Stable
};

inline QString channelName(Channel c) {
    switch (c) {
    case Channel::Development: return QStringLiteral("development");
    case Channel::Canary: return QStringLiteral("canary");
    case Channel::Beta: return QStringLiteral("beta");
    case Channel::Stable: return QStringLiteral("stable");
    }
    return QStringLiteral("unknown");
}

// Separate update lanes (SPEC-020-R02).
enum class UpdateLane {
    CoreApp,
    ProviderAdapter,
    ContextRules,
    CommandPack,
    PluginPack,
    RendererPack,
    AudioPack,
    LocalModelAsset,
    HelpIndex
};

inline QString laneName(UpdateLane l) {
    switch (l) {
    case UpdateLane::CoreApp: return QStringLiteral("core_app");
    case UpdateLane::ProviderAdapter: return QStringLiteral("provider_adapter");
    case UpdateLane::ContextRules: return QStringLiteral("context_rules");
    case UpdateLane::CommandPack: return QStringLiteral("command_pack");
    case UpdateLane::PluginPack: return QStringLiteral("plugin_pack");
    case UpdateLane::RendererPack: return QStringLiteral("renderer_pack");
    case UpdateLane::AudioPack: return QStringLiteral("audio_pack");
    case UpdateLane::LocalModelAsset: return QStringLiteral("local_model_asset");
    case UpdateLane::HelpIndex: return QStringLiteral("help_index");
    }
    return QStringLiteral("unknown");
}

// Staged rollout metadata (WM-FEAT-0232).
struct Rollout {
    double fraction = 1.0;     // offer fraction in (0,1]
    bool killSwitch = false;   // recall: nobody may install
};

// Compatibility declaration (SPEC-020-R04).
struct Compatibility {
    QString wiremudder;
    QString mudlet;
};

// The signed update manifest (WM-FEAT-0230). Verification happens in the
// Rust core; this struct is the schema-shaped transport.
struct SignedManifest {
    int schemaVersion = 1;
    UpdateLane lane = UpdateLane::CoreApp;
    Channel channel = Channel::Stable;
    QString version;
    QString artifactSha256;
    qint64 artifactSize = 0;
    QString signature;            // Ed25519 hex, 128 chars
    Compatibility compat;
    QSet<QString> requiredPermissions; // permission-expansion rejection
    Rollout rollout;
    bool hasRollout = false;
    quint32 migrationVersion = 0;
};

// Verification outcome (SPEC-025 typed states).
enum class VerifyState {
    Verified,
    DeniedUnsigned,
    DeniedInvalidSignature,
    DeniedHashMismatch,
    DeniedPermissionExpansion,
    DeniedDowngrade,
    DeniedIncompatible,
    DeferredActiveSessions,
    DeferredRollout,
    DeferredLockdown,
    Error
};

inline QString verifyStateName(VerifyState s) {
    switch (s) {
    case VerifyState::Verified: return QStringLiteral("verified");
    case VerifyState::DeniedUnsigned: return QStringLiteral("denied_unsigned");
    case VerifyState::DeniedInvalidSignature: return QStringLiteral("denied_invalid_signature");
    case VerifyState::DeniedHashMismatch: return QStringLiteral("denied_hash_mismatch");
    case VerifyState::DeniedPermissionExpansion: return QStringLiteral("denied_permission_expansion");
    case VerifyState::DeniedDowngrade: return QStringLiteral("denied_downgrade");
    case VerifyState::DeniedIncompatible: return QStringLiteral("denied_incompatible");
    case VerifyState::DeferredActiveSessions: return QStringLiteral("deferred_active_sessions");
    case VerifyState::DeferredRollout: return QStringLiteral("deferred_rollout");
    case VerifyState::DeferredLockdown: return QStringLiteral("deferred_lockdown");
    case VerifyState::Error: return QStringLiteral("error");
    }
    return QStringLiteral("unknown");
}

// Resumable download state (WM-FEAT-0233): contiguous chunks only.
struct ResumeState {
    QString manifestSha256;
    qint64 artifactSize = 0;
    qint64 bytesReceived = 0;

    bool complete() const { return bytesReceived >= artifactSize; }
};

// Health after an update (WM-SPEC-020-R06): healthy only after clean
// startup and smoke checks; crash loops quarantine and offer rollback.
enum class Health { Healthy, FailedStartup, CrashLoop };

inline QString healthName(Health h) {
    switch (h) {
    case Health::Healthy: return QStringLiteral("healthy");
    case Health::FailedStartup: return QStringLiteral("failed_startup");
    case Health::CrashLoop: return QStringLiteral("crash_loop");
    }
    return QStringLiteral("unknown");
}

// Migration decision (WM-FEAT-0237): backup before install, restore on
// rollback.
enum class MigrationState { NoMigrationNeeded, BackupRequired, ReadyToInstall, RestoreRequired };

// Lockdown (WM-FEAT-0240): Local Only Lockdown blocks remote update checks
// unless individually and visibly overridden by the user (SPEC-010-R04).
struct Lockdown {
    bool active = false;
    bool userOverride = false;

    bool allowsRemoteUpdateCheck() const { return !active || userOverride; }
};

// Boundary anchor (M3 wires the Rust core through this surface).
class UpdaterBoundary {
public:
    // Verify a signed manifest with the supplied public key (hex).
    // Implemented by the Rust wire-updater core via the bridge.
    static VerifyState verifyManifest(const SignedManifest& manifest,
                                      const QString& publicKeyHex,
                                      const QByteArray& manifestBytes);

    // Full admission check: permissions, downgrade, rollout, sessions,
    // lockdown (WM-SPEC-020-R04/R07, WM-SPEC-010-R04).
    static VerifyState admit(const SignedManifest& manifest,
                             const QSet<QString>& grantedPermissions,
                             const QString& currentVersion,
                             bool localOnlyLockdown,
                             quint32 activeSessions,
                             quint64 clientShare);

    // Health confirmation: clean startup resets the crash counter; a
    // bound of repeated failures quarantines and offers rollback.
    static Health recordStartup(bool ok, int quarantineAfter = 3);
};

} // namespace wiremudder::updater
