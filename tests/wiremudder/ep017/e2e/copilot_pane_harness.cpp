// EP-017 M3 E2E: Qt copilot pane state machine (real compiled C++ harness).
//
// Exercises the CopilotPaneQt boundary: initial state, ready transition,
// non-ready clearing, cancellation, bounded history, and passive observer
// guarantee. Compiled by the M3 E2E test script against the real header.
#include <cassert>
#include <iostream>

#include "src/wiremudder/ui/copilot/copilot_boundary.h"

using namespace wiremudder::ui;

int main() {
    CopilotPaneQt pane;

    // Initial state: unavailable, passive, no stale suggestion.
    assert(pane.state() == CopilotPaneState::Unavailable);
    assert(pane.stateLabel() == QStringLiteral("unavailable"));
    assert(pane.isPassive());
    assert(!pane.hasSuggestion());

    // Ready: a suggestion with citations, confidence, disclosure, and a
    // SPEC-009-gated action proposal.
    CopilotSuggestionQt s;
    s.text = QStringLiteral("suggest talking to the innkeeper about the key.");
    s.confidence = 0.55;
    s.uncertainty = QStringLiteral("moderate");
    WhyCitationQt cite;
    cite.kind = QStringLiteral("observation");
    cite.text = QStringLiteral("room: The Crossroads");
    s.citations.append(cite);
    s.why.evidence = s.citations;
    s.why.uncertainty = s.uncertainty;
    s.disclosure.providerId = QStringLiteral("ollama");
    s.disclosure.routeId = QStringLiteral("ollama-local");
    s.disclosure.privacyMode = QStringLiteral("local-preferred");
    s.disclosure.redactionPatterns = 8;
    s.disclosure.contextBytes = 512;
    s.disclosure.promptTokens = 132;
    s.disclosure.completionTokens = 12;
    s.disclosure.estimatedCostUsdMicros = 0;
    s.disclosure.latencyMs = 421;
    s.actionProposal.proposalId = QStringLiteral("ap-0000000000000001");
    s.actionProposal.command = QStringLiteral("ask innkeeper about key");
    s.actionProposal.requiresConfirmation = true;

    pane.setSuggestion(s);
    assert(pane.state() == CopilotPaneState::Ready);
    assert(pane.stateLabel() == QStringLiteral("ready"));
    assert(pane.hasSuggestion());
    assert(pane.suggestion().confidence > 0.0);
    assert(pane.suggestion().disclosure.providerId == QStringLiteral("ollama"));
    assert(pane.suggestion().actionProposal.requiresConfirmation);
    assert(pane.historyCount() == 1);

    // Degraded: provider unavailable -> suggestion cleared, state explicit.
    pane.setState(CopilotPaneState::Degraded);
    assert(pane.state() == CopilotPaneState::Degraded);
    assert(!pane.hasSuggestion());
    pane.setLastMessage(QStringLiteral("provider is unavailable"));
    assert(pane.lastMessage() == QStringLiteral("provider is unavailable"));

    // Denied: route denied -> no stale suggestion.
    pane.setState(CopilotPaneState::Denied);
    assert(pane.state() == CopilotPaneState::Denied);

    // Disabled: copilot disabled by policy.
    pane.setState(CopilotPaneState::Disabled);
    assert(pane.state() == CopilotPaneState::Disabled);

    // Cancel is distinct from failure.
    pane.requestCancel();
    assert(pane.state() == CopilotPaneState::Canceled);
    assert(pane.canceled());
    assert(!pane.hasSuggestion());

    // Error state.
    pane.setState(CopilotPaneState::Error);
    assert(pane.stateLabel() == QStringLiteral("error"));

    // Bounded history across several suggestions.
    pane.setMaxHistory(3);
    for (int i = 0; i < 5; ++i) {
        CopilotSuggestionQt q;
        q.text = QStringLiteral("suggestion %1").arg(i);
        pane.setSuggestion(q);
    }
    assert(pane.historyCount() == 3);
    assert(pane.history().last().text == QStringLiteral("suggestion 4"));

    std::cout << "E2E copilot pane: ok" << std::endl;
    return 0;
}
