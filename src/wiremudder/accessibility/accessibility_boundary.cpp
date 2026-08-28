// WireMudder Accessibility, Localization, and UX Hardening Boundary
// (EP-031 M2) - implementation.
//
// Model-side passive implementation: reflects real accessibility profile
// state and translation catalog data for the operator. This translation
// unit is wired into the inherited CMake source list beside help,
// soundscape, diagnostics, and import so the boundary compiles with the
// real Qt6 build.
#include "accessibility_boundary.h"

namespace wiremudder::ui::accessibility {

// The boundary is intentionally model-only at this layer; the widget
// surface that renders AccessibilityPaneModel lives behind the same
// header and stays passive (display + request flags, no mutation).
static_assert(sizeof(AccessibilityPaneModel) > 0, "AccessibilityPaneModel must be complete");

QString AccessibilityPaneModel::stateLabel() const
{
    switch (m_state) {
    case AccessibilityPaneState::Loading:
        return QStringLiteral("loading");
    case AccessibilityPaneState::Ready:
        return QStringLiteral("ready");
    case AccessibilityPaneState::Disabled:
        return QStringLiteral("disabled");
    case AccessibilityPaneState::Denied:
        return QStringLiteral("denied");
    case AccessibilityPaneState::Degraded:
        return QStringLiteral("degraded");
    case AccessibilityPaneState::Canceled:
        return QStringLiteral("canceled");
    case AccessibilityPaneState::Unavailable:
        return QStringLiteral("unavailable");
    case AccessibilityPaneState::Error:
        return QStringLiteral("error");
    }
    return QStringLiteral("unavailable");
}

QString AccessibilityPaneModel::catalogDisplay() const
{
    if (!m_catalog.valid) {
        return QStringLiteral("no-translation-catalog");
    }
    QString joined = m_catalog.locales.join(QLatin1Char(','));
    return QStringLiteral("%1@%2:%3[%4]").arg(m_catalog.name, m_catalog.resource, m_catalog.suffix, joined);
}

} // namespace wiremudder::ui::accessibility
