// WireMudder Assistance Boundary (EP-020 M3) - implementation.
#include "assistance_boundary.h"

namespace wiremudder::ui {

AssistancePaneQt::AssistancePaneQt() = default;

void AssistancePaneQt::setState(AssistancePaneState s)
{
    state_ = s;
    if (s != AssistancePaneState::Loading && s != AssistancePaneState::Ready) {
        clear();
    }
}

QString AssistancePaneQt::stateLabel() const
{
    switch (state_) {
    case AssistancePaneState::Loading:
        return QStringLiteral("loading");
    case AssistancePaneState::Ready:
        return QStringLiteral("ready");
    case AssistancePaneState::Disabled:
        return QStringLiteral("disabled");
    case AssistancePaneState::Denied:
        return QStringLiteral("denied");
    case AssistancePaneState::Degraded:
        return QStringLiteral("degraded");
    case AssistancePaneState::Canceled:
        return QStringLiteral("canceled");
    case AssistancePaneState::Unavailable:
        return QStringLiteral("unavailable");
    case AssistancePaneState::Error:
        return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

} // namespace wiremudder::ui
