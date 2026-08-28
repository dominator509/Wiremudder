// WireMudder Soul Boundary (EP-018 M3) - implementation.
#include "soul_boundary.h"

namespace wiremudder::ui {

SoulPaneQt::SoulPaneQt() = default;

void SoulPaneQt::setState(SoulPaneState s) {
    state_ = s;
    if (s != SoulPaneState::Loading && s != SoulPaneState::Ready) {
        clear();
    }
}

QString SoulPaneQt::stateLabel() const {
    switch (state_) {
        case SoulPaneState::Loading: return QStringLiteral("loading");
        case SoulPaneState::Ready: return QStringLiteral("ready");
        case SoulPaneState::Disabled: return QStringLiteral("disabled");
        case SoulPaneState::Denied: return QStringLiteral("denied");
        case SoulPaneState::Degraded: return QStringLiteral("degraded");
        case SoulPaneState::Canceled: return QStringLiteral("canceled");
        case SoulPaneState::Unavailable: return QStringLiteral("unavailable");
        case SoulPaneState::Error: return QStringLiteral("error");
    }
    return QStringLiteral("error");
}

} // namespace wiremudder::ui
