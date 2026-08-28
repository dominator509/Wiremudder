// WireMudder Voice Companion Boundary (EP-024 M3)
//
// Ambient Voice Companion and Voice Macros pane surface (WM-FEAT-0057,
// WM-FEAT-0058, WM-FEAT-0059, WM-FEAT-0060, WM-FEAT-0061, WM-FEAT-0062,
// WM-FEAT-0063, WM-FEAT-0064, WM-FEAT-0065, WM-FEAT-0066, WM-FEAT-0067,
// WM-FEAT-0068, WM-FEAT-0186, WM-FEAT-0211, WM-FEAT-0212; SPEC-015,
// SPEC-009, SPEC-010, SPEC-022). Shows:
//   - Microphone state (always visible: off, listening, speaking,
//     barge-in, error, disabled).
//   - Push-to-talk / hold-to-talk activation.
//   - Optional wake phrase (disabled by default, consented).
//   - Bounded speech queue with load-shedding.
//   - Voice macros that produce Action Proposals through the
//     deterministic command-safety gate (never auto-send on this
//     surface).
//   - Per-character and per-agent licensed voice styles.
//   - Subtitles with private-content suppression.
// The pane is a passive observer: it displays data and surfaces user
// intent (approve proposal) as request flags; it NEVER sends commands
// and has no command path of its own.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded,
// Canceled, Unavailable, Error. Optional failure preserves manual text
// gameplay (WM-SPEC-015-R10).
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

enum class VoicePaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// Microphone state. Always visible; there is no hidden capture state.
enum class VoiceMicState {
    Off,
    Listening,
    Speaking,
    BargeIn,
    Error,
    Disabled,
};

// One visible voice macro (passes command safety; never auto-sends).
struct VoiceMacroQt
{
    QString id;
    QString name;
    QString phrase;
    QString command;
    QString riskTier; // manual | low | medium | high | critical
    bool confirmationRequired = false;
    bool approved = false;
};

// One licensed voice style (protected identities require authorization).
struct VoiceStyleQt
{
    QString id;
    QString label;
    QString kind; // character | agent
    QString license;
    bool authorized = false;
    bool protectedIdentity = false;
};

// One subtitle line (private content suppressed by default).
struct SubtitleLineQt
{
    QString text;
    bool privateLine = false;
    quint64 atMs = 0;
};

// Voice Companion pane. Model-side Qt surface; no QWidget dependency.
// Passive: never sends commands, never grants itself authority, mic
// state is always visible.
class VoicePaneQt
{
public:
    explicit VoicePaneQt();

    VoicePaneState state() const { return state_; }
    void setState(VoicePaneState s);
    QString stateLabel() const;

    // Microphone state is always visible (WM-SPEC-015-R01).
    VoiceMicState micState() const { return mic_; }
    void setMicState(VoiceMicState m) { mic_ = m; }
    QString micLabel() const;

    // Activation mode.
    QString activation() const { return activation_; }
    void setActivation(const QString& a) { activation_ = a; }

    // Wake phrase (optional, disabled by default).
    bool wakePhraseEnabled() const { return wakePhraseEnabled_; }
    void setWakePhraseEnabled(bool e) { wakePhraseEnabled_ = e; }

    // Speech queue.
    void setQueueLen(int n) { queueLen_ = n; }
    int queueLen() const { return queueLen_; }
    void setLoadShed(bool s) { loadShed_ = s; }
    bool loadShed() const { return loadShed_; }

    // Voice macros (command-safety gated).
    void setMacros(const QVector<VoiceMacroQt>& m) { macros_ = m; }
    int macroCount() const { return macros_.size(); }
    const QVector<VoiceMacroQt>& macros() const { return macros_; }
    // User intent: approve a proposal. The pane only records the
    // request; the command-safety gate performs the approval.
    void requestApproveProposal(const QString& id) { approveRequested_ = id; }
    QString approveProposalRequested() const { return approveRequested_; }

    // Voice styles.
    void setStyles(const QVector<VoiceStyleQt>& s) { styles_ = s; }
    int styleCount() const { return styles_.size(); }
    const QVector<VoiceStyleQt>& styles() const { return styles_; }

    // Subtitles (private suppressed by default).
    void setSubtitles(const QVector<SubtitleLineQt>& s) { subtitles_ = s; }
    int subtitleCount() const { return subtitles_.size(); }
    const QVector<SubtitleLineQt>& subtitles() const { return subtitles_; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No command path exists on this boundary (no hidden auto-send).
    bool canSendCommand() const { return false; }
    bool canEditGates() const { return false; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    void clear()
    {
        macros_.clear();
        styles_.clear();
        subtitles_.clear();
        approveRequested_.clear();
        queueLen_ = 0;
        loadShed_ = false;
    }

private:
    VoicePaneState state_ = VoicePaneState::Unavailable;
    VoiceMicState mic_ = VoiceMicState::Off;
    QString activation_ = QStringLiteral("push-to-talk");
    bool wakePhraseEnabled_ = false;
    int queueLen_ = 0;
    bool loadShed_ = false;
    QVector<VoiceMacroQt> macros_;
    QVector<VoiceStyleQt> styles_;
    QVector<SubtitleLineQt> subtitles_;
    QString approveRequested_;
    QString lastMessage_;
};

} // namespace wiremudder::ui
