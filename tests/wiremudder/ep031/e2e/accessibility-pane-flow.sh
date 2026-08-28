#!/usr/bin/env sh
# EP-031 M3 e2e test: a real user-visible flow through the accessibility
# boundary model — the accessibility pane reflects real profile state for
# every SPEC-025 state, raw text stays visible even when the pane is
# degraded or denied, and the translation catalog convention is displayed
# from real catalog data. Exercises loading, ready, disabled, denied,
# degraded, canceled, unavailable, and error states.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "e2e: FAIL - $1" >&2; exit 1; }

QTDIR=/opt/qt/6.8.2/gcc_64
[ -d "$QTDIR/include/QtCore" ] || fail "Qt6 not found at $QTDIR"

cat > /tmp/ep031_e2e_harness.cpp <<'CPP'
#include "wiremudder/accessibility/accessibility_boundary.h"
#include <cstdio>

using wiremudder::ui::accessibility::AccessibilityPaneModel;
using wiremudder::ui::accessibility::AccessibilityPaneState;
using wiremudder::ui::accessibility::AccessibilityProfile;
using wiremudder::ui::accessibility::TranslationCatalog;

#define CHECK(cond)                                                       \
    do {                                                                  \
        if (!(cond)) {                                                    \
            std::fprintf(stderr, "e2e: FAIL - %s (line %d)\n", #cond, __LINE__); \
            return 1;                                                     \
        }                                                                 \
    } while (0)

int main()
{
    AccessibilityPaneModel model;
    TranslationCatalog catalog;
    catalog.valid = true;
    catalog.name = QStringLiteral("wiremudder");
    catalog.resource = QStringLiteral(":/lang");
    catalog.suffix = QStringLiteral(".qm");
    catalog.locales = {QStringLiteral("de_DE"), QStringLiteral("fr_FR"), QStringLiteral("zh_CN")};
    model.setCatalog(catalog);

    // Real user-visible flow: pane reports a healthy accessibility profile.
    AccessibilityProfile healthy;
    healthy.valid = true;
    healthy.keyboard_operable = true;
    healthy.visible_focus = true;
    healthy.screen_reader_labels = true;
    healthy.non_color_state = true;
    healthy.large_text_resilient = true;
    healthy.reduced_motion = true;
    healthy.no_animation = true;
    healthy.subtitles_available = true;
    healthy.raw_text_mode = true;
    healthy.raw_text_authoritative = true;
    model.setProfile(healthy);
    model.setState(AccessibilityPaneState::Ready);
    CHECK(model.stateLabel() == QLatin1String("ready"));
    CHECK(model.catalogDisplay() == QLatin1String("wiremudder@:/lang:.qm[de_DE,fr_FR,zh_CN]"));

    // Every SPEC-025 state is representable without hiding raw text.
    const AccessibilityPaneState states[] = {
        AccessibilityPaneState::Loading,
        AccessibilityPaneState::Ready,
        AccessibilityPaneState::Disabled,
        AccessibilityPaneState::Denied,
        AccessibilityPaneState::Degraded,
        AccessibilityPaneState::Canceled,
        AccessibilityPaneState::Unavailable,
        AccessibilityPaneState::Error,
    };
    for (auto s : states) {
        model.setState(s);
        CHECK(!model.stateLabel().isEmpty());
        CHECK(model.rawTextAlwaysVisible());
        CHECK(!model.canSendCommand());
        CHECK(!model.canChangeSettings());
        CHECK(!model.canDisableRawText());
    }

    // Degraded/denied states: raw terminal text remains visible and
    // authoritative (WM-SPEC-007-R03, WM-SPEC-016-R04).
    AccessibilityProfile degraded;
    degraded.valid = true;
    degraded.raw_text_mode = false; // hostile attempt to hide raw text
    model.setProfile(degraded);
    model.setState(AccessibilityPaneState::Denied);
    CHECK(model.rawTextAlwaysVisible());
    CHECK(model.profile().raw_text_authoritative);

    std::printf("e2e accessibility-pane-flow: ok\n");
    return 0;
}
CPP

out=$(mktemp /tmp/ep031_e2e_XXXX.log)
g++ -std=c++17 -fPIC -I"$QTDIR/include" -I"$QTDIR/include/QtCore" \
  -I src \
  /tmp/ep031_e2e_harness.cpp \
  src/wiremudder/accessibility/accessibility_boundary.cpp \
  -L"$QTDIR/lib" -Wl,-rpath,"$QTDIR/lib" -lQt6Core \
  -o /tmp/ep031_e2e_harness 2>"$out" || {
  cat "$out" >&2
  fail "e2e harness did not compile against Qt6"
}
if grep -q "warning:" "$out"; then
  cat "$out" >&2
  fail "e2e harness compiled with warnings"
fi

LD_LIBRARY_PATH="$QTDIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  /tmp/ep031_e2e_harness >"$out" 2>&1 || {
  cat "$out" >&2
  fail "e2e harness failed"
}
grep -q "e2e accessibility-pane-flow: ok" "$out" || fail "e2e sentinel missing"

echo "e2e EP-031 accessibility-pane-flow: ok"
