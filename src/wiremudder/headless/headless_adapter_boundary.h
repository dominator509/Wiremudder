// WireMudder Headless Adapter Boundary (EP-023 M3)
//
// Desktop-side headless adapter surface (WM-FEAT-0121, WM-SPEC-017-R04,
// WM-SPEC-017-R06). The actual headless runtime lives in the
// wire-headless crate and the supervisor CLI tool; this boundary is the
// C++ adapter contract a desktop session uses to reach the same
// scheduler, policy gates, and emergency stop (WM-SPEC-024-R08: desktop
// and headless commands use the same application contracts and policy
// gates).
//
// The adapter is a passive observer: it reports session state, room,
// last command, AI/autopilot state, risk queue, route label, token
// spend, health, and queue length. It NEVER sends commands and has no
// command path of its own; the session scheduler owns enqueue and the
// global emergency stop.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded,
// Canceled, Unavailable, Error.
#pragma once

#include <QString>
#include <QVector>

namespace wiremudder::headless {

enum class HeadlessAdapterState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// One session snapshot for the desktop adapter (WM-SPEC-017-R06).
struct HeadlessSessionQt {
    QString sessionId;
    QString state;
    QString room;
    QString lastCommand;
    QString aiState;
    QString autopilotState;
    int riskQueueLen = 0;
    QString routeLabel;
    quint64 tokenSpend = 0;
    QString health;
    int queueLen = 0;
};

// Headless adapter. Model-side Qt surface; no QWidget dependency.
// Passive: never sends commands, never grants itself authority, and
// never triggers the global emergency stop (the scheduler owns it).
class HeadlessAdapterQt {
public:
    explicit HeadlessAdapterQt();

    HeadlessAdapterState state() const { return state_; }
    void setState(HeadlessAdapterState s);
    QString stateLabel() const;

    void setSessions(const QVector<HeadlessSessionQt>& s) { sessions_ = s; }
    int sessionCount() const { return sessions_.size(); }
    const QVector<HeadlessSessionQt>& sessions() const { return sessions_; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No command path exists on this boundary (no hidden auto-send, no
    // emergency-stop authority).
    bool canSendCommand() const { return false; }
    bool canEmergencyStop() const { return false; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    void clear() { sessions_.clear(); }

private:
    HeadlessAdapterState state_ = HeadlessAdapterState::Unavailable;
    QVector<HeadlessSessionQt> sessions_;
    QString lastMessage_;
};

} // namespace wiremudder::headless
