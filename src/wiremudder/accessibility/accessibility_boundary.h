// WireMudder Accessibility, Localization, and UX Hardening Boundary
// (EP-031 M2)
//
// Cross-cutting accessibility surface for the WireMudder desktop
// (SPEC-007, SPEC-015, SPEC-016, SPEC-018, SPEC-027; WM-SPEC-007-R05
// obligations verified across enabled surfaces, WM-SPEC-007-R10 owned).
// The boundary is a passive observer: it exposes the accessibility
// profile state (keyboard operation, visible focus, screen-reader
// labels, non-color-only state, large-text resilience, reduced-motion,
// no-animation, subtitles, raw-text mode) and the translation catalog
// convention (catalog name, locale set, translator context). It NEVER
// sends commands, NEVER changes settings, and has no mutation path.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded,
// Canceled, Unavailable, Error. Accessibility state never blocks text
// gameplay; raw terminal text remains visible and authoritative
// (WM-SPEC-007-R03, WM-SPEC-016-R04).
#pragma once

#include <QString>
#include <QStringList>

namespace wiremudder::ui::accessibility {

enum class AccessibilityPaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

struct AccessibilityProfile
{
    bool valid = false;
    bool keyboard_operable = false;
    bool visible_focus = false;
    bool screen_reader_labels = false;
    bool non_color_state = false;
    bool large_text_resilient = false;
    bool reduced_motion = false;
    bool no_animation = false;
    bool subtitles_available = false;
    bool raw_text_mode = true;          // raw terminal text always visible
    bool raw_text_authoritative = true; // server text never spoofs commands
};

struct TranslationCatalog
{
    bool valid = false;
    QString name;                   // e.g. "wiremudder" (inherited Mudlet convention)
    QString resource;               // e.g. ":/lang" (inherited runtime load path)
    QString suffix;                 // e.g. ".qm"
    QStringList locales;            // e.g. {"de_DE", "fr_FR", ...}
    bool translator_context = true; // WM-SPEC-007-R10
};

// Passive view-model: the pane only reflects real accessibility state and
// catalog data; it never mutates anything itself.
class AccessibilityPaneModel
{
public:
    AccessibilityPaneModel() = default;

    void setProfile(const AccessibilityProfile& profile) { m_profile = profile; }
    AccessibilityProfile profile() const { return m_profile; }

    void setCatalog(const TranslationCatalog& catalog) { m_catalog = catalog; }
    TranslationCatalog catalog() const { return m_catalog; }

    void setState(AccessibilityPaneState state) { m_state = state; }
    AccessibilityPaneState state() const { return m_state; }

    QString stateLabel() const;
    QString catalogDisplay() const;

    // Passive-surface invariants (EP-031).
    bool isPassive() const { return true; }
    bool canSendCommand() const { return false; }
    bool canChangeSettings() const { return false; }
    bool canAccessSecrets() const { return false; }
    bool canEgress() const { return false; }
    bool canDisableRawText() const { return false; }
    bool rawTextAlwaysVisible() const { return true; }
    bool translatorContextRequired() const { return true; } // WM-SPEC-007-R10

    // Reset per load; no mutation of any surface state.
    void reset()
    {
        m_profile = AccessibilityProfile{};
        m_catalog = TranslationCatalog{};
        m_state = AccessibilityPaneState::Loading;
    }

private:
    AccessibilityProfile m_profile;
    TranslationCatalog m_catalog;
    AccessibilityPaneState m_state = AccessibilityPaneState::Loading;
};

} // namespace wiremudder::ui::accessibility
