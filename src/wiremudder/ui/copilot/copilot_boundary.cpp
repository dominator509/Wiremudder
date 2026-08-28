// WireMudder Copilot Boundary (EP-017 M3) - implementation.
#include "copilot_boundary.h"

namespace wiremudder::ui {

CopilotPaneQt::CopilotPaneQt() = default;

void CopilotPaneQt::setState(CopilotPaneState s)
{
    state_ = s;
    if (s != CopilotPaneState::Loading && s != CopilotPaneState::Ready) {
        // A non-ready state clears the suggestion; the player is never
        // shown stale advice (degradation is explicit).
        clear();
    }
}

QString CopilotPaneQt::stateLabel() const
{
    switch (state_) {
    case CopilotPaneState::Loading:
        return QStringLiteral("loading");
    case CopilotPaneState::Ready:
        return QStringLiteral("ready");
    case CopilotPaneState::Disabled:
        return QStringLiteral("disabled");
    case CopilotPaneState::Denied:
        return QStringLiteral("denied");
    case CopilotPaneState::Degraded:
        return QStringLiteral("degraded");
    case CopilotPaneState::Canceled:
        return QStringLiteral("canceled");
    case CopilotPaneState::Unavailable:
        return QStringLiteral("unavailable");
    case CopilotPaneState::Error:
        return QStringLiteral("error");
    }
    return QStringLiteral("error");
}

void CopilotPaneQt::setSuggestion(const CopilotSuggestionQt& s)
{
    suggestion_ = s;
    state_ = CopilotPaneState::Ready;
    history_.append(s);
    if (history_.size() > maxHistory_) {
        history_.removeFirst();
    }
}

void CopilotPaneQt::clear()
{
    suggestion_ = CopilotSuggestionQt{};
}

void CopilotPaneQt::requestCancel()
{
    canceled_ = true;
    state_ = CopilotPaneState::Canceled;
    clear();
}

} // namespace wiremudder::ui
