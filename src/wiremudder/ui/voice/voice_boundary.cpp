// WireMudder Voice Companion Boundary (EP-024 M3) - implementation.
#include "voice_boundary.h"

namespace wiremudder::ui {

VoicePaneQt::VoicePaneQt() = default;

void VoicePaneQt::setState(VoicePaneState s)
{
    state_ = s;
    if (s != VoicePaneState::Loading && s != VoicePaneState::Ready) {
        clear();
    }
}

QString VoicePaneQt::stateLabel() const
{
    switch (state_) {
    case VoicePaneState::Loading:
        return QStringLiteral("loading");
    case VoicePaneState::Ready:
        return QStringLiteral("ready");
    case VoicePaneState::Disabled:
        return QStringLiteral("disabled");
    case VoicePaneState::Denied:
        return QStringLiteral("denied");
    case VoicePaneState::Degraded:
        return QStringLiteral("degraded");
    case VoicePaneState::Canceled:
        return QStringLiteral("canceled");
    case VoicePaneState::Unavailable:
        return QStringLiteral("unavailable");
    case VoicePaneState::Error:
        return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

QString VoicePaneQt::micLabel() const
{
    switch (mic_) {
    case VoiceMicState::Off:
        return QStringLiteral("off");
    case VoiceMicState::Listening:
        return QStringLiteral("listening");
    case VoiceMicState::Speaking:
        return QStringLiteral("speaking");
    case VoiceMicState::BargeIn:
        return QStringLiteral("barge-in");
    case VoiceMicState::Error:
        return QStringLiteral("error");
    case VoiceMicState::Disabled:
        return QStringLiteral("disabled");
    }
    return QStringLiteral("off");
}

} // namespace wiremudder::ui
