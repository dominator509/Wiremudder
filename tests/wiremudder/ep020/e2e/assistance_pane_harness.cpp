// WireMudder Assistance Pane Harness (EP-020 M3).
//
// Real compiled harness: links the actual assistance_boundary.cpp surface
// and exercises the user-visible flow: loading -> ready with a cited
// quest, bounded tactical snapshot, and redacted narrator summary. Proves
// the pane compiles into a real binary and behaves deterministically.
//
// Build (run from the test dir):
//   g++ -std=c++17 -fPIC $(pkg-config --cflags Qt5Core) \
//     assistance_pane_harness.cpp \
//     ../../../../src/wiremudder/ui/assistance/assistance_boundary.cpp \
//     $(pkg-config --libs Qt5Core) -o /tmp/ep020_assistance_harness
#include "src/wiremudder/ui/assistance/assistance_boundary.h"
#include <cstdio>

using wiremudder::ui::AssistancePaneQt;
using wiremudder::ui::AssistancePaneState;
using wiremudder::ui::QuestEntryQt;
using wiremudder::ui::QuestClueQt;
using wiremudder::ui::TacticalSnapshotQt;
using wiremudder::ui::NarratorSummaryQt;

static int failures = 0;
#define CHECK(cond) do { if (!(cond)) { std::printf("HARNESS FAIL: %s (line %d)\n", #cond, __LINE__); ++failures; } } while (0)

int main() {
    AssistancePaneQt pane;
    CHECK(pane.isPassive());
    CHECK(!pane.canSendCommand());
    CHECK(pane.state() == AssistancePaneState::Unavailable);

    // Loading -> Ready.
    pane.setState(AssistancePaneState::Loading);
    CHECK(pane.stateLabel() == QStringLiteral("loading"));
    pane.setState(AssistancePaneState::Ready);
    CHECK(pane.stateLabel() == QStringLiteral("ready"));

    // Quest Compass: cited quest with visible uncertainty.
    QuestEntryQt q;
    q.questId = QStringLiteral("q1");
    q.title = QStringLiteral("Find the key");
    q.state = QStringLiteral("inferred");
    q.uncertainty = QStringLiteral("inferred, not yet observed");
    QuestClueQt clue;
    clue.text = QStringLiteral("the guard mentioned a key");
    clue.citedFrom = QStringLiteral("room:gate");
    q.clues.append(clue);
    QVector<QuestEntryQt> quests;
    quests.append(q);
    pane.setQuests(quests);
    CHECK(pane.questCount() == 1);
    CHECK(pane.quests()[0].clues[0].citedFrom == QStringLiteral("room:gate"));

    // Tactical HUD: bounded current snapshot.
    TacticalSnapshotQt t;
    t.room = QStringLiteral("crossroads");
    t.healthPct = 80;
    t.energyPct = 50;
    t.threatLevel = QStringLiteral("low");
    t.nearbyEntities.append(QStringLiteral("guard"));
    pane.setTactical(t);
    CHECK(pane.hasTactical());
    CHECK(pane.tactical().room == QStringLiteral("crossroads"));

    // Narrator: summary discloses source and redaction flag.
    NarratorSummaryQt s;
    s.text = QStringLiteral("Quest 'Find the key' is inferred.");
    s.source = QStringLiteral("quest");
    s.redacted = false;
    QVector<NarratorSummaryQt> summaries;
    summaries.append(s);
    pane.setSummaries(summaries);
    CHECK(pane.summaryCount() == 1);
    CHECK(pane.summaries()[0].source == QStringLiteral("quest"));

    // Non-ready state clears the pane (SPEC-025 deterministic behavior).
    pane.setState(AssistancePaneState::Denied);
    CHECK(pane.stateLabel() == QStringLiteral("denied"));
    CHECK(pane.questCount() == 0);
    CHECK(!pane.hasTactical());

    if (failures == 0) {
        std::printf("assistance pane harness: ok\n");
        return 0;
    }
    std::printf("assistance pane harness: FAIL (%d checks)\n", failures);
    return 1;
}
