// WireMudder Contextual Help, Setup Coach, and Source Index Boundary
// (EP-027 M3)
//
// Help bubbles, safe defaults, validation/privacy guidance, local Help
// Knowledge Index, Ask WireMudder AI handoff, world capability
// onboarding, CLI parity, and opt-in source indexing pane surface
// (WM-FEAT-0109, WM-FEAT-0111, WM-FEAT-0112, WM-FEAT-0187,
// WM-FEAT-0213..WM-FEAT-0219; SPEC-018, SPEC-007, SPEC-010,
// SPEC-022). Shows:
//   - Help bubbles with safe defaults, validation hints, privacy notes,
//     and documentation links.
//   - Setup Coach steps that explain and propose only (never apply).
//   - Help modes: local-only, remote-redacted, disabled.
//   - Ask WireMudder AI handoff with scoped sanitized context.
//   - Evidence-based world capability probes with confirmation status.
//   - Optional source index state (opt-in, local, idle, removable).
// The pane is a passive observer: it displays data and surfaces user
// intent (open bubble, propose step) as request flags; it NEVER sends
// commands, NEVER changes settings, and has no mutation path
// (WM-SPEC-018-R06).
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded,
// Canceled, Unavailable, Error. Help never blocks settings interaction
// or gameplay (WM-SPEC-018-R10).
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

enum class HelpPaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// Help mode per privacy policy (SPEC-018-R03).
enum class HelpModeQt {
    LocalOnly,
    RemoteRedacted,
    Disabled,
};

// One help bubble (WM-SPEC-018-R01).
struct HelpBubbleQt
{
    QString fieldId;
    QString label;
    QString safeDefault;
    QString validationHint;
    QString privacyNote;
    QString docLink;
};

// One coach step: explain and propose only (WM-SPEC-018-R06).
struct CoachStepQt
{
    QString id;
    QString title;
    QString explanation;
    QString proposal;
    bool canApply = false; // always false on this surface
};

// One evidence-based capability probe (WM-SPEC-018-R08).
struct CapabilityProbeQt
{
    QString name;
    bool observed = false;
    QStringList evidence;
    bool confirmed = false;
};

// Source index state (WM-SPEC-018-R05).
struct SourceIndexQt
{
    bool enabled = false;
    bool localOnly = true;
    bool idleOnly = true;
    int indexedEntries = 0;
    int secretSkipped = 0;
    int ignoredSkipped = 0;
    bool removed = false;
};

// Help pane. Model-side Qt surface; no QWidget dependency.
// Passive: never sends commands, never mutates settings.
class HelpPaneQt
{
public:
    explicit HelpPaneQt();

    HelpPaneState state() const { return state_; }
    void setState(HelpPaneState s);
    QString stateLabel() const;

    // Help bubbles.
    void setBubbles(const QVector<HelpBubbleQt>& b) { bubbles_ = b; }
    int bubbleCount() const { return bubbles_.size(); }
    const QVector<HelpBubbleQt>& bubbles() const { return bubbles_; }
    // User intent: open a bubble. Records request only.
    void requestOpenBubble(const QString& fieldId) { openBubbleRequested_ = fieldId; }
    QString openBubbleRequested() const { return openBubbleRequested_; }

    // Setup Coach steps (propose only).
    void setCoachSteps(const QVector<CoachStepQt>& s) { coachSteps_ = s; }
    int coachStepCount() const { return coachSteps_.size(); }
    const QVector<CoachStepQt>& coachSteps() const { return coachSteps_; }
    void requestProposeStep(const QString& id) { proposeStepRequested_ = id; }
    QString proposeStepRequested() const { return proposeStepRequested_; }
    // The coach cannot apply anything on this surface.
    bool coachCanApply() const { return false; }

    // Help mode.
    HelpModeQt mode() const { return mode_; }
    void setMode(HelpModeQt m) { mode_ = m; }
    QString modeLabel() const;

    // Ask WireMudder AI handoff (scoped sanitized context).
    void setAskContext(const QString& fieldId, const QString& sanitizedState, const QString& validationError, const QStringList& approvedRefs)
    {
        askFieldId_ = fieldId;
        askSanitizedState_ = sanitizedState;
        askValidationError_ = validationError;
        askApprovedRefs_ = approvedRefs;
    }
    QString askFieldId() const { return askFieldId_; }
    QString askSanitizedState() const { return askSanitizedState_; }
    QString askValidationError() const { return askValidationError_; }
    QStringList askApprovedRefs() const { return askApprovedRefs_; }

    // Capability probes.
    void setCapabilities(const QVector<CapabilityProbeQt>& c) { capabilities_ = c; }
    int capabilityCount() const { return capabilities_.size(); }
    const QVector<CapabilityProbeQt>& capabilities() const { return capabilities_; }

    // Source index state.
    void setSourceIndex(const SourceIndexQt& s) { sourceIndex_ = s; }
    SourceIndexQt sourceIndex() const { return sourceIndex_; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No command path and no mutation path on this boundary.
    bool canSendCommand() const { return false; }
    bool canEditGates() const { return false; }
    bool canChangeSettings() const { return false; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    void clear()
    {
        bubbles_.clear();
        coachSteps_.clear();
        capabilities_.clear();
        openBubbleRequested_.clear();
        proposeStepRequested_.clear();
        askFieldId_.clear();
        askSanitizedState_.clear();
        askValidationError_.clear();
        askApprovedRefs_.clear();
        sourceIndex_ = SourceIndexQt();
    }

private:
    HelpPaneState state_ = HelpPaneState::Unavailable;
    HelpModeQt mode_ = HelpModeQt::LocalOnly;
    QVector<HelpBubbleQt> bubbles_;
    QVector<CoachStepQt> coachSteps_;
    QVector<CapabilityProbeQt> capabilities_;
    SourceIndexQt sourceIndex_;
    QString openBubbleRequested_;
    QString proposeStepRequested_;
    QString askFieldId_;
    QString askSanitizedState_;
    QString askValidationError_;
    QStringList askApprovedRefs_;
    QString lastMessage_;
};

} // namespace wiremudder::ui
