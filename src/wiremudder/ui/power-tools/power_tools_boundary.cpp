// WireMudder Power Tools Boundary (EP-022 M3) - implementation.
#include "power_tools_boundary.h"

namespace wiremudder::ui {

PowerToolsPaneQt::PowerToolsPaneQt() = default;

void PowerToolsPaneQt::setState(PowerToolsPaneState s)
{
    state_ = s;
    if (s != PowerToolsPaneState::Loading && s != PowerToolsPaneState::Ready) {
        clear();
    }
}

QString PowerToolsPaneQt::stateLabel() const
{
    switch (state_) {
    case PowerToolsPaneState::Loading:
        return QStringLiteral("loading");
    case PowerToolsPaneState::Ready:
        return QStringLiteral("ready");
    case PowerToolsPaneState::Disabled:
        return QStringLiteral("disabled");
    case PowerToolsPaneState::Denied:
        return QStringLiteral("denied");
    case PowerToolsPaneState::Degraded:
        return QStringLiteral("degraded");
    case PowerToolsPaneState::Canceled:
        return QStringLiteral("canceled");
    case PowerToolsPaneState::Unavailable:
        return QStringLiteral("unavailable");
    case PowerToolsPaneState::Error:
        return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

} // namespace wiremudder::ui
