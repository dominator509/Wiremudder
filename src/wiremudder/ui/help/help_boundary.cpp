// WireMudder Contextual Help, Setup Coach, and Source Index Boundary
// (EP-027 M3) - implementation.
#include "help_boundary.h"

namespace wiremudder::ui {

HelpPaneQt::HelpPaneQt() = default;

void HelpPaneQt::setState(HelpPaneState s) {
    state_ = s;
    if (s != HelpPaneState::Loading && s != HelpPaneState::Ready) {
        clear();
    }
}

QString HelpPaneQt::stateLabel() const {
    switch (state_) {
        case HelpPaneState::Loading: return QStringLiteral("loading");
        case HelpPaneState::Ready: return QStringLiteral("ready");
        case HelpPaneState::Disabled: return QStringLiteral("disabled");
        case HelpPaneState::Denied: return QStringLiteral("denied");
        case HelpPaneState::Degraded: return QStringLiteral("degraded");
        case HelpPaneState::Canceled: return QStringLiteral("canceled");
        case HelpPaneState::Unavailable: return QStringLiteral("unavailable");
        case HelpPaneState::Error: return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

QString HelpPaneQt::modeLabel() const {
    switch (mode_) {
        case HelpModeQt::LocalOnly: return QStringLiteral("local-only");
        case HelpModeQt::RemoteRedacted: return QStringLiteral("remote-redacted");
        case HelpModeQt::Disabled: return QStringLiteral("disabled");
    }
    return QStringLiteral("local-only");
}

} // namespace wiremudder::ui
