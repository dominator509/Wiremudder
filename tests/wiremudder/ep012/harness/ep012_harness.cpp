// EP-012 M2 test harness: exercises the real terminal, workspace, and
// editor boundaries with deterministic invariants.
// Subcommands: terminal | workspace | editor
#include <QCoreApplication>
#include <cstdio>

#include "src/wiremudder/ui/terminal_boundary.h"
#include "src/wiremudder/ui/workspace_boundary.h"
#include "src/wiremudder/ui/editor_boundary.h"

using namespace wiremudder::ui;
using namespace wiremudder::models;

static int fail(const char* msg) {
    std::fprintf(stderr, "FAIL: %s\n", msg);
    return 1;
}

static int cmdTerminal() {
    // 1. WM-SPEC-007-R03: raw text visible immediately, unmodified.
    TerminalPaneQt pane(10);
    pane.appendRaw("look north");
    pane.appendRaw("A winding path leads into the hills.");
    if (pane.lineCount() != 2) return fail("line count");
    if (pane.lastLine() != "A winding path leads into the hills.") return fail("last line raw");

    // 2. Scrollback bound (WM-FEAT-0003): overflow drops oldest, never newest.
    for (int i = 0; i < 15; ++i) pane.appendRaw(QString("line-%1").arg(i));
    if (pane.lineCount() != 10) return fail("scrollback bound");
    if (!pane.overflowDropped()) return fail("overflow not flagged");
    if (pane.lastLine() != "line-14") return fail("newest preserved");
    if (pane.snapshot().first() != "line-5") return fail("oldest dropped");

    // 3. Command history navigation (WM-FEAT-0004).
    CommandHistoryQt hist(500);
    hist.add("say hello");
    hist.add("look");
    hist.add("look"); // consecutive dedup
    if (hist.count() != 2) return fail("history dedup");
    if (hist.up() != "look") return fail("history up");
    if (hist.up() != "say hello") return fail("history up 2");
    if (hist.down() != "look") return fail("history down");
    if (hist.down() != QString()) return fail("history down new");

    // 4. History persistence round-trip (WM-SPEC-007-R04).
    CommandHistoryQt hist2(500);
    hist2.fromJson(hist.toJson());
    if (hist2.all() != hist.all()) return fail("history round-trip");

    // 5. Capture pane (WM-FEAT-0011): filtered copy, source untouched.
    CapturePaneQt cap(50);
    CaptureFilter f;
    f.id = "tell";
    f.match = "tells you";
    cap.setFilter(f);
    cap.ingest("Bob tells you, 'hello'");
    cap.ingest("The forest is quiet.");
    cap.ingest("ALICE TELLS YOU, 'hi'"); // case-insensitive
    if (cap.count() != 2) return fail("capture count");
    if (cap.captured().first() != "Bob tells you, 'hello'") return fail("capture first");

    std::printf("terminal boundary: ok\n");
    return 0;
}

static int cmdWorkspace() {
    // 1. Status gauges (WM-FEAT-0012).
    StatusGaugeQt gauges;
    StatusGauge hp;
    hp.id = "hp";
    hp.label = "Hit Points";
    hp.value = "87";
    hp.min = 0;
    hp.max = 100;
    gauges.set(hp);
    if (!gauges.has("hp")) return fail("gauge has");
    if (gauges.value("hp") != "87") return fail("gauge value");
    StatusGauge hp2 = hp;
    hp2.value = "42";
    gauges.set(hp2);
    if (gauges.count() != 1 || gauges.value("hp") != "42") return fail("gauge update");

    // 2. Theme contrast state (WM-FEAT-0021, WM-SPEC-027-R07).
    ThemeQt theme("highcon");
    theme.setColors("#ffffff", "#000000");
    theme.setHighContrast(true);
    if (!theme.highContrast()) return fail("high contrast");
    if (theme.ansiColors().size() != 16) return fail("ansi palette");

    // 3. Workspace layout persistence round-trip (WM-SPEC-007-R04).
    WorkspaceLayoutQt layout("combat");
    DockPaneSpec capture;
    capture.id = "capture";
    capture.title = "Capture";
    capture.position = "bottom";
    layout.addDock(capture);
    DockPaneSpec gaugedock;
    gaugedock.id = "gauges";
    gaugedock.title = "Gauges";
    layout.addDock(gaugedock);
    layout.gauges().set(hp);
    layout.theme().setName("highcon");

    const QJsonObject json = layout.toJson();
    WorkspaceLayoutQt restored("x");
    if (!restored.fromJson(json)) return fail("layout restore");
    if (restored.name() != "combat") return fail("layout name");
    if (!restored.hasDock("capture") || !restored.hasDock("gauges")) return fail("layout docks");
    if (restored.docks().at(0).position != "bottom") return fail("dock position");
    if (restored.gauges().value("hp") != "87") return fail("gauge persisted");
    if (restored.theme().name() != "highcon") return fail("theme persisted");

    // 4. Dock removal.
    layout.removeDock("gauges");
    if (layout.hasDock("gauges")) return fail("dock removal");

    std::printf("workspace boundary: ok\n");
    return 0;
}

static int cmdEditor() {
    // 1. Spellcheck known words (WM-FEAT-0018).
    SpellcheckCore sc;
    if (!sc.isKnown("look")) return fail("known word");
    if (sc.isKnown("lokk")) return fail("unknown word accepted");

    // 2. Suggestion quality.
    QStringList s = sc.suggest("lokk");
    if (s.isEmpty() || s.first() != "look") return fail("suggestion");

    // 3. Autocorrect map + fallback.
    sc.addCorrection("teh", "the");
    sc.addWord("wiremudder");
    if (sc.autocorrect("teh") != "the") return fail("autocorrect map");
    if (sc.autocorrect("lokk") != "look") return fail("autocorrect suggestion");
    if (sc.autocorrect("zzzz") != "zzzz") return fail("autocorrect unchanged");

    // 4. Completion (WM-FEAT-0019).
    CompletionCore cc;
    cc.add("north");
    cc.add("northeast");
    cc.add("say");
    if (cc.candidates("no").size() != 2) return fail("completion prefix");
    if (cc.candidates("northeast").first() != "northeast") return fail("completion exact");
    if (cc.candidates("zzz").size() != 0) return fail("completion empty");

    std::printf("editor boundary: ok\n");
    return 0;
}

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    if (argc < 2) { std::fprintf(stderr, "usage: harness terminal|workspace|editor\n"); return 2; }
    const QString cmd = QString::fromUtf8(argv[1]);
    if (cmd == "terminal") return cmdTerminal();
    if (cmd == "workspace") return cmdWorkspace();
    if (cmd == "editor") return cmdEditor();
    std::fprintf(stderr, "bad subcommand\n");
    return 2;
}
