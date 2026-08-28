// EP-031 M2 unit harness: compiles the accessibility boundary against the
// real Qt6 toolchain and asserts the deterministic model invariants.
// Returns non-zero on any failed assertion.
#include "wiremudder/accessibility/accessibility_boundary.h"

#include <cstdio>

using wiremudder::ui::accessibility::AccessibilityPaneModel;
using wiremudder::ui::accessibility::AccessibilityPaneState;
using wiremudder::ui::accessibility::AccessibilityProfile;
using wiremudder::ui::accessibility::TranslationCatalog;

#define CHECK(cond)                                                       \
    do {                                                                  \
        if (!(cond)) {                                                    \
            std::fprintf(stderr, "EP-031 unit: FAIL - %s (line %d)\n", #cond, __LINE__); \
            return 1;                                                     \
        }                                                                 \
    } while (0)

int main()
{
    AccessibilityPaneModel model;

    // Default state is Loading; reset returns to Loading.
    CHECK(model.state() == AccessibilityPaneState::Loading);
    model.setState(AccessibilityPaneState::Ready);
    CHECK(model.state() == AccessibilityPaneState::Ready);
    CHECK(model.stateLabel() == QLatin1String("ready"));
    model.setState(AccessibilityPaneState::Error);
    CHECK(model.stateLabel() == QLatin1String("error"));
    model.reset();
    CHECK(model.state() == AccessibilityPaneState::Loading);

    // Passive-surface invariants (EP-031).
    CHECK(model.isPassive());
    CHECK(!model.canSendCommand());
    CHECK(!model.canChangeSettings());
    CHECK(!model.canAccessSecrets());
    CHECK(!model.canEgress());
    CHECK(!model.canDisableRawText());
    CHECK(model.rawTextAlwaysVisible());
    CHECK(model.translatorContextRequired());

    // Profile reflects raw text authority and the R05 obligations.
    AccessibilityProfile profile;
    profile.valid = true;
    profile.keyboard_operable = true;
    profile.visible_focus = true;
    profile.screen_reader_labels = true;
    profile.non_color_state = true;
    profile.large_text_resilient = true;
    profile.reduced_motion = true;
    profile.no_animation = true;
    profile.subtitles_available = true;
    profile.raw_text_mode = true;
    profile.raw_text_authoritative = true;
    model.setProfile(profile);
    CHECK(model.profile().valid);
    CHECK(model.profile().keyboard_operable);
    CHECK(model.profile().visible_focus);
    CHECK(model.profile().screen_reader_labels);
    CHECK(model.profile().non_color_state);
    CHECK(model.profile().large_text_resilient);
    CHECK(model.profile().reduced_motion);
    CHECK(model.profile().no_animation);
    CHECK(model.profile().subtitles_available);
    CHECK(model.profile().raw_text_mode);
    CHECK(model.profile().raw_text_authoritative);

    // Raw text can never be hidden or delayed (WM-SPEC-007-R03, R16-R04).
    AccessibilityProfile degraded;
    degraded.valid = true;
    degraded.raw_text_mode = false; // attempt to hide raw text
    model.setProfile(degraded);
    CHECK(model.rawTextAlwaysVisible());

    // Translation catalog follows the inherited Mudlet convention
    // (WM-SPEC-007-R10): name, resource prefix, suffix, locales.
    TranslationCatalog catalog;
    catalog.valid = true;
    catalog.name = QStringLiteral("wiremudder");
    catalog.resource = QStringLiteral(":/lang");
    catalog.suffix = QStringLiteral(".qm");
    catalog.locales = {QStringLiteral("de_DE"), QStringLiteral("fr_FR")};
    catalog.translator_context = true;
    model.setCatalog(catalog);
    CHECK(model.catalog().valid);
    CHECK(model.catalogDisplay() == QLatin1String("wiremudder@:/lang:.qm[de_DE,fr_FR]"));
    CHECK(model.translatorContextRequired());

    // Invalid catalog displays the fallback.
    model.setCatalog(TranslationCatalog{});
    CHECK(model.catalogDisplay() == QLatin1String("no-translation-catalog"));

    std::printf("unit accessibility-boundary: ok\n");
    return 0;
}
