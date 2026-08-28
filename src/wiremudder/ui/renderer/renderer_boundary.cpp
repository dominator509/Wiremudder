// WireMudder Retro Renderer Boundary (EP-025 M3) - implementation.
#include "renderer_boundary.h"

namespace wiremudder::ui {

RendererPaneQt::RendererPaneQt() = default;

void RendererPaneQt::setState(RendererPaneState s)
{
    state_ = s;
    if (s != RendererPaneState::Loading && s != RendererPaneState::Ready) {
        clear();
    }
}

QString RendererPaneQt::stateLabel() const
{
    switch (state_) {
    case RendererPaneState::Loading:
        return QStringLiteral("loading");
    case RendererPaneState::Ready:
        return QStringLiteral("ready");
    case RendererPaneState::Disabled:
        return QStringLiteral("disabled");
    case RendererPaneState::Denied:
        return QStringLiteral("denied");
    case RendererPaneState::Degraded:
        return QStringLiteral("degraded");
    case RendererPaneState::Canceled:
        return QStringLiteral("canceled");
    case RendererPaneState::Unavailable:
        return QStringLiteral("unavailable");
    case RendererPaneState::Error:
        return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

} // namespace wiremudder::ui
