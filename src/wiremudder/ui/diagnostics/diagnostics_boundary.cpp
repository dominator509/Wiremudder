// WireMudder Telemetry, Replay, and Diagnostic Bundles Boundary (EP-028 M3)
// - implementation.
#include "diagnostics_boundary.h"

namespace wiremudder::ui {

DiagnosticsPaneQt::DiagnosticsPaneQt() = default;

void DiagnosticsPaneQt::setState(DiagnosticsPaneState s)
{
    state_ = s;
    if (s != DiagnosticsPaneState::Loading && s != DiagnosticsPaneState::Ready) {
        clear();
    }
}

QString DiagnosticsPaneQt::stateLabel() const
{
    switch (state_) {
    case DiagnosticsPaneState::Loading:
        return QStringLiteral("loading");
    case DiagnosticsPaneState::Ready:
        return QStringLiteral("ready");
    case DiagnosticsPaneState::Disabled:
        return QStringLiteral("disabled");
    case DiagnosticsPaneState::Denied:
        return QStringLiteral("denied");
    case DiagnosticsPaneState::Degraded:
        return QStringLiteral("degraded");
    case DiagnosticsPaneState::Canceled:
        return QStringLiteral("canceled");
    case DiagnosticsPaneState::Unavailable:
        return QStringLiteral("unavailable");
    case DiagnosticsPaneState::Error:
        return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

} // namespace wiremudder::ui
