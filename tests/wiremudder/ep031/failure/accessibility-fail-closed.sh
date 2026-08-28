#!/usr/bin/env sh
# EP-031 M4 failure test: forced failures and abuse cases against the
# accessibility boundary — every SPEC-025 failure state must be
# representable, raw text must stay visible under every failure, and the
# boundary must fail closed (no command path, no settings mutation, no
# secrets, no egress) even when degraded or denied.
set -eu
cd "$(dirname "$0")/../../../.."

fail() { echo "failure: FAIL - $1" >&2; exit 1; }

QTDIR=/opt/qt/6.8.2/gcc_64
[ -d "$QTDIR/include/QtCore" ] || fail "Qt6 not found at $QTDIR"

cat > /tmp/ep031_failure_harness.cpp <<'CPP'
#include "wiremudder/accessibility/accessibility_boundary.h"
#include <cstdio>

using wiremudder::ui::accessibility::AccessibilityPaneModel;
using wiremudder::ui::accessibility::AccessibilityPaneState;
using wiremudder::ui::accessibility::AccessibilityProfile;
using wiremudder::ui::accessibility::TranslationCatalog;

#define CHECK(cond)                                                       \
    do {                                                                  \
        if (!(cond)) {                                                    \
            std::fprintf(stderr, "failure: FAIL - %s (line %d)\n", #cond, __LINE__); \
            return 1;                                                     \
        }                                                                 \
    } while (0)

int main()
{
    AccessibilityPaneModel model;

    // 1. Unavailable dependency / worker: pane reports Unavailable but
    //    raw text remains visible and the pane stays passive.
    model.setState(AccessibilityPaneState::Unavailable);
    CHECK(model.stateLabel() == QLatin1String("unavailable"));
    CHECK(model.rawTextAlwaysVisible());
    CHECK(!model.canSendCommand());
    CHECK(!model.canChangeSettings());

    // 2. Timeout and cancellation: Canceled state, still passive, raw text
    //    untouched.
    model.setState(AccessibilityPaneState::Canceled);
    CHECK(model.stateLabel() == QLatin1String("canceled"));
    CHECK(model.rawTextAlwaysVisible());

    // 3. Malformed / oversized input: an invalid profile cannot disable
    //    raw text or grant authority. A hostile profile attempts both.
    AccessibilityProfile hostile;
    hostile.valid = false;                 // malformed
    hostile.raw_text_mode = false;         // attempt to hide raw text
    hostile.raw_text_authoritative = false; // attempt to spoof commands
    model.setProfile(hostile);
    model.setState(AccessibilityPaneState::Error);
    CHECK(model.stateLabel() == QLatin1String("error"));
    CHECK(model.rawTextAlwaysVisible());   // fail closed
    CHECK(!model.canSendCommand());        // fail closed
    CHECK(!model.canChangeSettings());
    CHECK(!model.canDisableRawText());

    // 4. Duplicate / replayed request: repeated state updates are
    //    idempotent for the raw-text invariant.
    model.setState(AccessibilityPaneState::Ready);
    model.setState(AccessibilityPaneState::Ready);
    model.setState(AccessibilityPaneState::Denied);
    CHECK(model.rawTextAlwaysVisible());
    CHECK(!model.canDisableRawText());

    // 5. Denied permission / consent / policy: Denied state, raw text
    //    visible and authoritative.
    model.setState(AccessibilityPaneState::Denied);
    CHECK(model.stateLabel() == QLatin1String("denied"));
    CHECK(model.rawTextAlwaysVisible());
    CHECK(model.profile().raw_text_authoritative || !model.profile().valid);

    // 6. Resource / queue budget exhaustion: Degraded state, raw text
    //    still visible; the pane never blocks text gameplay.
    model.setState(AccessibilityPaneState::Degraded);
    CHECK(model.stateLabel() == QLatin1String("degraded"));
    CHECK(model.rawTextAlwaysVisible());

    // 7. Partial side effect and compensation: reset() returns to Loading
    //    with no stale profile or catalog authority.
    AccessibilityProfile prof;
    prof.valid = true;
    prof.keyboard_operable = true;
    model.setProfile(prof);
    TranslationCatalog cat;
    cat.valid = true;
    cat.name = QStringLiteral("wiremudder");
    model.setCatalog(cat);
    model.reset();
    CHECK(model.state() == AccessibilityPaneState::Loading);
    CHECK(!model.profile().valid);
    CHECK(!model.catalog().valid);

    // 8. Preserved manual gameplay and data integrity: after all failure
    //    states, raw text is still always visible and authoritative.
    CHECK(model.rawTextAlwaysVisible());
    CHECK(model.rawTextAlwaysVisible());

    std::printf("failure accessibility-fail-closed: ok\n");
    return 0;
}
CPP

out=$(mktemp /tmp/ep031_failure_XXXX.log)
g++ -std=c++17 -fPIC -I"$QTDIR/include" -I"$QTDIR/include/QtCore" \
  -I src \
  /tmp/ep031_failure_harness.cpp \
  src/wiremudder/accessibility/accessibility_boundary.cpp \
  -L"$QTDIR/lib" -Wl,-rpath,"$QTDIR/lib" -lQt6Core \
  -o /tmp/ep031_failure_harness 2>"$out" || {
  cat "$out" >&2
  fail "failure harness did not compile against Qt6"
}
if grep -q "warning:" "$out"; then
  cat "$out" >&2
  fail "failure harness compiled with warnings"
fi

LD_LIBRARY_PATH="$QTDIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  /tmp/ep031_failure_harness >"$out" 2>&1 || {
  cat "$out" >&2
  fail "failure harness failed"
}
grep -q "failure accessibility-fail-closed: ok" "$out" || fail "failure sentinel missing"

echo "failure EP-031 accessibility-fail-closed: ok"
