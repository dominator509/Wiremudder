// WireMudder Autopilot Boundary (EP-019 M3)
//
// Guarded Autopilot pane surface (WM-FEAT-0041, WM-SPEC-014-R10). Shows
// the autopilot status (disabled/ready/paused/denied/error), the visible
// bounded pending-action queue with confirmation requirements, the narrow
// allowlist, stale-state reason, and the last action time. The pane is a
// passive observer: it displays data and surfaces user intent (confirm,
// cancel, emergency stop) as request flags; it NEVER sends commands and
// has no command path of its own. Every actual send is performed by the
// autopilot engine through the deterministic Action Gateway.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded, Canceled,
// Unavailable, Error. Optional failure preserves manual text gameplay.
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

enum class AutopilotPaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// One visible pending action (WM-SPEC-009-R08 visible queue).
struct PendingActionQt
{
    QString proposalId;
    QString command;
    bool requiresConfirmation = false;
    QString status; // awaiting-confirmation | approved-visible
    QString riskTier;
};

// Guarded Autopilot pane. Model-side Qt surface; no QWidget dependency.
// Passive: never sends commands, never grants itself authority.
class AutopilotPaneQt
{
public:
    explicit AutopilotPaneQt();

    AutopilotPaneState state() const { return state_; }
    void setState(AutopilotPaneState s);
    QString stateLabel() const;

    // Status surface.
    void setMode(const QString& m) { mode_ = m; } // disabled | confirm-every | allowlist-auto
    QString mode() const { return mode_; }
    void setProfile(const QString& p) { profile_ = p; }
    QString profile() const { return profile_; }
    void setStaleReason(const QString& r) { staleReason_ = r; }
    QString staleReason() const { return staleReason_; }
    void setLastActionAtMs(quint64 ms) { lastActionAtMs_ = ms; }
    quint64 lastActionAtMs() const { return lastActionAtMs_; }

    // Visible bounded queue (WM-SPEC-009-R08).
    void setPending(const QVector<PendingActionQt>& p) { pending_ = p; }
    int pendingCount() const { return pending_.size(); }
    const QVector<PendingActionQt>& pending() const { return pending_; }

    // Narrow user allowlist (WM-SPEC-009-R04).
    void setAllowlist(const QStringList& a) { allowlist_ = a; }
    QStringList allowlist() const { return allowlist_; }

    // User intent surfaces (confirm/cancel/emergency stop). The pane only
    // records the request; the engine performs the action. There is no
    // command-send path on this boundary.
    void requestConfirm(const QString& proposalId) { confirmRequested_ = proposalId; }
    QString confirmRequested() const { return confirmRequested_; }
    void requestCancel(const QString& proposalId) { cancelRequested_ = proposalId; }
    QString cancelRequested() const { return cancelRequested_; }
    void requestEmergencyStop() { emergencyStopRequested_ = true; }
    bool emergencyStopRequested() const { return emergencyStopRequested_; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No command path exists on this boundary (no hidden auto-send).
    bool canSendCommand() const { return false; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    void clear()
    {
        mode_.clear();
        profile_.clear();
        staleReason_.clear();
        lastActionAtMs_ = 0;
        pending_.clear();
        allowlist_.clear();
        confirmRequested_.clear();
        cancelRequested_.clear();
        emergencyStopRequested_ = false;
    }

private:
    AutopilotPaneState state_ = AutopilotPaneState::Unavailable;
    QString mode_;
    QString profile_;
    QString staleReason_;
    quint64 lastActionAtMs_ = 0;
    QVector<PendingActionQt> pending_;
    QStringList allowlist_;
    QString confirmRequested_;
    QString cancelRequested_;
    bool emergencyStopRequested_ = false;
    QString lastMessage_;
};

} // namespace wiremudder::ui
