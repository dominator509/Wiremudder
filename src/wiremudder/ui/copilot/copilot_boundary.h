// WireMudder Copilot Boundary (EP-017 M3)
//
// Player Copilot pane surface (WM-FEAT-0040, WM-SPEC-014-R01). Suggestion-
// only: the pane holds suggestions, cited Why explanations, calibrated
// confidence, uncertainty, and visible disclosures (context, provider,
// redaction, token, cost). It NEVER sends commands: an Action Proposal is
// an explicit, visible struct that requires SPEC-009 confirmation before any
// execution, and this boundary has no execute path.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded, Canceled,
// Unavailable, Error. Optional failure preserves manual text gameplay: the
// pane is a passive observer and never blocks or mutates the terminal.
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

// Copilot pane state (SPEC-025 error classes, mapped to UI states).
enum class CopilotPaneState {
    Loading,     // provider request in flight
    Ready,       // suggestion available
    Disabled,    // copilot disabled by policy/config
    Denied,      // route or policy denied
    Degraded,    // deterministic hints only (provider unavailable/failed)
    Canceled,    // request canceled by the player
    Unavailable, // no provider configured or reachable
    Error,       // invariant/security error
};

// One cited piece of evidence for a Why explanation (WM-SPEC-014-R09).
struct WhyCitationQt
{
    QString kind; // observation | memory | policy | rejected-alternative
    QString text; // redacted before display
};

// Why explanation: cited evidence + uncertainty + rejected alternatives.
struct WhyExplanationQt
{
    QVector<WhyCitationQt> evidence;
    QString uncertainty;
    QStringList rejectedAlternatives;
    bool degraded = false;
};

// Visible disclosure (acceptance obligation 5).
struct CopilotDisclosureQt
{
    QString providerId;
    QString routeId;
    QString privacyMode;
    int redactionPatterns = 0;
    int contextBytes = 0;
    int promptTokens = 0;
    int completionTokens = 0;
    quint64 estimatedCostUsdMicros = 0;
    quint64 latencyMs = 0;
    bool degraded = false;
};

// Explicit Action Proposal. NEVER executed by this boundary; requires
// SPEC-009 confirmation (WM-SPEC-014-R10, SPEC-009).
struct ActionProposalQt
{
    QString proposalId;
    QString command;
    int riskTier = 1;
    bool requiresConfirmation = true;
    QString reason;
};

// One copilot suggestion (WM-FEAT-0040).
struct CopilotSuggestionQt
{
    QString text; // redacted suggestion text
    QVector<WhyCitationQt> citations;
    double confidence = 0.0; // calibrated, non-authoritative (R08)
    QString uncertainty;
    WhyExplanationQt why;
    CopilotDisclosureQt disclosure;
    ActionProposalQt actionProposal; // empty proposalId => none
};

// Player Copilot pane (WM-FEAT-0040, WM-FEAT-0046, WM-FEAT-0047).
// Model-side Qt surface; no QWidget dependency. The pane is a passive
// observer: it holds state and never sends commands or mutates the terminal.
class CopilotPaneQt
{
public:
    explicit CopilotPaneQt();

    // State machine.
    CopilotPaneState state() const { return state_; }
    void setState(CopilotPaneState s);
    QString stateLabel() const;

    // Suggestion lifecycle.
    void setSuggestion(const CopilotSuggestionQt& s);
    bool hasSuggestion() const { return !suggestion_.text.isEmpty(); }
    const CopilotSuggestionQt& suggestion() const { return suggestion_; }
    void clear();

    // Cancellation (SPEC-025-R07): distinct from failure.
    void requestCancel();
    bool canceled() const { return canceled_; }

    // Manual gameplay is preserved: the pane never touches the terminal.
    bool isPassive() const { return true; }

    // Bounded history of recent suggestions (per-profile).
    void setMaxHistory(int n) { maxHistory_ = n; }
    int historyCount() const { return history_.size(); }
    const QVector<CopilotSuggestionQt>& history() const { return history_; }

    // Last user-facing message (redacted, SPEC-025-R09).
    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

private:
    CopilotPaneState state_ = CopilotPaneState::Unavailable;
    CopilotSuggestionQt suggestion_;
    QVector<CopilotSuggestionQt> history_;
    int maxHistory_ = 50;
    bool canceled_ = false;
    QString lastMessage_;
};

} // namespace wiremudder::ui
