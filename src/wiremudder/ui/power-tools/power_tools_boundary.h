// WireMudder Power Tools Boundary (EP-022 M3)
//
// Macro Forge, Trigger Test Lab, and AI Debugger pane surface (WM-FEAT-0106,
// WM-FEAT-0107, WM-FEAT-0108, WM-FEAT-0127, WM-FEAT-0161, WM-FEAT-0162;
// SPEC-008, SPEC-019). Shows:
//   - Macro Forge drafts (preview-only until approved; disabled until
//     approved; approved drafts still never auto-send on this surface).
//   - Trigger Test Lab fixtures and last deterministic replay runs.
//   - AI Debugger diagnoses that cite evidence, never self-certify, and
//     never edit gates.
//   - Variable inspection with privacy scopes (private values redacted).
//   - Event timeline.
//   - Performance statistics with slow-offender diagnostics.
// The pane is a passive observer: it displays data and surfaces user
// intent (approve draft, approve evidence) as request flags; it NEVER
// sends commands and has no command path of its own. Suggested patches
// always require normal Graphlock validation (EP-022 obligation 6).
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded, Canceled,
// Unavailable, Error. Optional failure preserves manual text gameplay.
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

enum class PowerToolsPaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// One Macro Forge automation draft (disabled until approved).
struct AutomationDraftQt
{
    QString id;
    QString kind; // macro | trigger
    QString name;
    QString body;
    bool approved = false;
    bool previewOnly = true;
};

// One Trigger Test Lab fixture with its last replay run summary.
struct ReplayFixtureQt
{
    QString id;
    QString name;
    int steps = 0;
    int matched = 0;
    bool lastFinished = false;
    QString lastDenied; // empty when none
};

// One AI Debugger diagnosis (cites evidence; never self-certifies).
struct AiDiagnosisQt
{
    QString id;
    QStringList evidence;
    QString hypothesis;
    QString reproduction;
    QString patchPlan;
    QStringList tests;
    QString risk;
    QString rollback;
    bool selfCertified = false; // R06: always false
    bool gateEditable = false;  // never true
};

// One inspected variable (privacy-scoped; private values redacted).
struct InspectedVariableQt
{
    QString name;
    QString scope; // public | private
    QString value; // "<redacted>" for private
};

// One event on the debug timeline.
struct DebugEventQt
{
    quint64 seq = 0;
    quint64 atMs = 0;
    QString source;
    QString line;
    bool redacted = false;
};

// One budget sample / slow offender.
struct BudgetSampleQt
{
    QString runId;
    QString kind;
    QString name;
    quint64 elapsedMs = 0;
    quint64 budgetMs = 0;
    bool overBudget = false;
};

// Power Tools pane. Model-side Qt surface; no QWidget dependency.
// Passive: never sends commands, never grants itself authority.
class PowerToolsPaneQt
{
public:
    explicit PowerToolsPaneQt();

    PowerToolsPaneState state() const { return state_; }
    void setState(PowerToolsPaneState s);
    QString stateLabel() const;

    // Macro Forge surface.
    void setDrafts(const QVector<AutomationDraftQt>& d) { drafts_ = d; }
    int draftCount() const { return drafts_.size(); }
    const QVector<AutomationDraftQt>& drafts() const { return drafts_; }
    // User intent: approve a draft. The pane only records the request;
    // the Macro Forge engine performs the approval. No send path.
    void requestApproveDraft(const QString& id) { approveDraftRequested_ = id; }
    QString approveDraftRequested() const { return approveDraftRequested_; }

    // Trigger Test Lab surface.
    void setFixtures(const QVector<ReplayFixtureQt>& f) { fixtures_ = f; }
    int fixtureCount() const { return fixtures_.size(); }
    const QVector<ReplayFixtureQt>& fixtures() const { return fixtures_; }

    // AI Debugger surface.
    void setDiagnoses(const QVector<AiDiagnosisQt>& d) { diagnoses_ = d; }
    int diagnosisCount() const { return diagnoses_.size(); }
    const QVector<AiDiagnosisQt>& diagnoses() const { return diagnoses_; }

    // Variable inspection (privacy-scoped).
    void setVariables(const QVector<InspectedVariableQt>& v) { variables_ = v; }
    int variableCount() const { return variables_.size(); }
    const QVector<InspectedVariableQt>& variables() const { return variables_; }

    // Event timeline.
    void setTimeline(const QVector<DebugEventQt>& t) { timeline_ = t; }
    int timelineCount() const { return timeline_.size(); }
    const QVector<DebugEventQt>& timeline() const { return timeline_; }

    // Performance statistics.
    void setBudgetSamples(const QVector<BudgetSampleQt>& s) { samples_ = s; }
    int budgetSampleCount() const { return samples_.size(); }
    const QVector<BudgetSampleQt>& budgetSamples() const { return samples_; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No command path exists on this boundary (no hidden auto-send, no
    // patch application; suggested patches require Graphlock validation).
    bool canSendCommand() const { return false; }
    bool canEditGates() const { return false; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    void clear()
    {
        drafts_.clear();
        fixtures_.clear();
        diagnoses_.clear();
        variables_.clear();
        timeline_.clear();
        samples_.clear();
        approveDraftRequested_.clear();
    }

private:
    PowerToolsPaneState state_ = PowerToolsPaneState::Unavailable;
    QVector<AutomationDraftQt> drafts_;
    QVector<ReplayFixtureQt> fixtures_;
    QVector<AiDiagnosisQt> diagnoses_;
    QVector<InspectedVariableQt> variables_;
    QVector<DebugEventQt> timeline_;
    QVector<BudgetSampleQt> samples_;
    QString approveDraftRequested_;
    QString lastMessage_;
};

} // namespace wiremudder::ui
