// WireMudder Headless Adapter Boundary (EP-023 M3) - implementation.
#include "headless_adapter_boundary.h"

namespace wiremudder::headless {

HeadlessAdapterQt::HeadlessAdapterQt() = default;

void HeadlessAdapterQt::setState(HeadlessAdapterState s) {
    state_ = s;
    if (s != HeadlessAdapterState::Loading && s != HeadlessAdapterState::Ready) {
        clear();
    }
}

QString HeadlessAdapterQt::stateLabel() const {
    switch (state_) {
        case HeadlessAdapterState::Loading: return QStringLiteral("loading");
        case HeadlessAdapterState::Ready: return QStringLiteral("ready");
        case HeadlessAdapterState::Disabled: return QStringLiteral("disabled");
        case HeadlessAdapterState::Denied: return QStringLiteral("denied");
        case HeadlessAdapterState::Degraded: return QStringLiteral("degraded");
        case HeadlessAdapterState::Canceled: return QStringLiteral("canceled");
        case HeadlessAdapterState::Unavailable: return QStringLiteral("unavailable");
        case HeadlessAdapterState::Error: return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

} // namespace wiremudder::headless
