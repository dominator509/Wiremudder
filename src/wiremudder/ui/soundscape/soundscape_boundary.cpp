// WireMudder Soundscape Engine and Audio Studio Boundary (EP-026 M3) -
// implementation.
#include "soundscape_boundary.h"

namespace wiremudder::ui {

SoundscapePaneQt::SoundscapePaneQt() = default;

void SoundscapePaneQt::setState(SoundscapePaneState s) {
    state_ = s;
    if (s != SoundscapePaneState::Loading && s != SoundscapePaneState::Ready) {
        clear();
    }
}

QString SoundscapePaneQt::stateLabel() const {
    switch (state_) {
        case SoundscapePaneState::Loading: return QStringLiteral("loading");
        case SoundscapePaneState::Ready: return QStringLiteral("ready");
        case SoundscapePaneState::Disabled: return QStringLiteral("disabled");
        case SoundscapePaneState::Denied: return QStringLiteral("denied");
        case SoundscapePaneState::Degraded: return QStringLiteral("degraded");
        case SoundscapePaneState::Canceled: return QStringLiteral("canceled");
        case SoundscapePaneState::Unavailable: return QStringLiteral("unavailable");
        case SoundscapePaneState::Error: return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

QString SoundscapePaneQt::modeLabel() const {
    switch (mode_) {
        case SoundscapeModeQt::Disabled: return QStringLiteral("disabled");
        case SoundscapeModeQt::Muted: return QStringLiteral("muted");
        case SoundscapeModeQt::Manual: return QStringLiteral("manual");
        case SoundscapeModeQt::Auto: return QStringLiteral("auto");
    }
    return QStringLiteral("disabled");
}

} // namespace wiremudder::ui
