// WireMudder Autopilot Boundary (EP-019 M3) - implementation.
#include "autopilot_boundary.h"

namespace wiremudder::ui {

AutopilotPaneQt::AutopilotPaneQt() = default;

void AutopilotPaneQt::setState(AutopilotPaneState s)
{
    state_ = s;
    if (s != AutopilotPaneState::Loading && s != AutopilotPaneState::Ready) {
        clear();
    }
}

QString AutopilotPaneQt::stateLabel() const
{
    switch (state_) {
    case AutopilotPaneState::Loading:
        return QStringLiteral("loading");
    case AutopilotPaneState::Ready:
        return QStringLiteral("ready");
    case AutopilotPaneState::Disabled:
        return QStringLiteral("disabled");
    case AutopilotPaneState::Denied:
        return QStringLiteral("denied");
    case AutopilotPaneState::Degraded:
        return QStringLiteral("degraded");
    case AutopilotPaneState::Canceled:
        return QStringLiteral("canceled");
    case AutopilotPaneState::Unavailable:
        return QStringLiteral("unavailable");
    case AutopilotPaneState::Error:
        return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

} // namespace wiremudder::ui
