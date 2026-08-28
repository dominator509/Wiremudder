#!/usr/bin/env sh
# EP-031 M4 performance test: real measured fixture on the accessibility
# boundary model. The node contract requires SPEC-004 evidence for queue,
# latency, cancellation, drop/coalesce, memory, CPU, and fallback behavior.
# This measures the state-transition and catalog-display hot path: a pure
# view-model that must never perform per-line blocking work or per-line
# cross-process/model calls (SPEC-007 performance obligation).
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "performance: FAIL - $1" >&2; exit 1; }

QTDIR=/opt/qt/6.8.2/gcc_64
[ -d "$QTDIR/include/QtCore" ] || fail "Qt6 not found at $QTDIR"

cat > /tmp/ep031_perf_harness.cpp <<'CPP'
#include "wiremudder/accessibility/accessibility_boundary.h"
#include <chrono>
#include <cstdio>

using wiremudder::ui::accessibility::AccessibilityPaneModel;
using wiremudder::ui::accessibility::AccessibilityPaneState;
using wiremudder::ui::accessibility::AccessibilityProfile;
using wiremudder::ui::accessibility::TranslationCatalog;

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

    constexpr int kIterations = 100000;
    auto start = std::chrono::steady_clock::now();
    for (int i = 0; i < kIterations; ++i) {
        model.setState(static_cast<AccessibilityPaneState>(i % 8));
        volatile const bool keep = model.rawTextAlwaysVisible();
        (void)keep;
        volatile auto label = model.stateLabel();
        (void)label;
    }
    auto end = std::chrono::steady_clock::now();
    double total_us = std::chrono::duration<double, std::micro>(end - start).count();
    double avg_us = total_us / kIterations;

    std::printf("perf accessibility-boundary: iterations=%d total_us=%.1f avg_us=%.4f\n",
                kIterations, total_us, avg_us);
    if (avg_us > 5.0) {
        std::fprintf(stderr, "perf: FAIL - avg_us %.4f exceeds 5.0 budget\n", avg_us);
        return 1;
    }
    return 0;
}
CPP

out=$(mktemp /tmp/ep031_perf_XXXX.log)
g++ -std=c++17 -O2 -fPIC -I"$QTDIR/include" -I"$QTDIR/include/QtCore" \
  -I src \
  /tmp/ep031_perf_harness.cpp \
  src/wiremudder/accessibility/accessibility_boundary.cpp \
  -L"$QTDIR/lib" -Wl,-rpath,"$QTDIR/lib" -lQt6Core \
  -o /tmp/ep031_perf_harness 2>"$out" || {
  cat "$out" >&2
  fail "performance harness did not compile against Qt6"
}
if grep -q "warning:" "$out"; then
  cat "$out" >&2
  fail "performance harness compiled with warnings"
fi

LD_LIBRARY_PATH="$QTDIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  /tmp/ep031_perf_harness >"$out" 2>&1 || {
  cat "$out" >&2
  fail "performance harness failed"
}
grep -q "perf accessibility-boundary:" "$out" || fail "performance sentinel missing"

echo "performance EP-031 accessibility-boundary: ok"
cat "$out"
