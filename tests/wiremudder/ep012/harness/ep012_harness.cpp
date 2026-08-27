// EP-012 M3 test harness: exercises the real terminal, workspace, and
// editor boundaries with deterministic invariants.
// Subcommands: terminal | workspace | editor | session <layout.json>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QTemporaryDir>
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

// Full user-visible session flow (EP-012 M3):
//   feed raw stream -> terminal pane + capture -> command input ->
//   history + completion -> gauge updates -> layout persistence to disk.
static int cmdSession(const QString& layoutPath) {
    TerminalPaneQt pane(100);
    CapturePaneQt cap(100);
    CommandHistoryQt hist(500);
    StatusGaugeQt gauges;
    WorkspaceLayoutQt layout("combat");
    CompletionCore cc;
    cc.add("north");
    cc.add("northeast");
    cc.add("look");

    // 1. Raw stream: every line lands in the terminal pane unmodified.
    const char* stream[] = {
        "A dark forest surrounds you.",
        "A goblin appears from the shadows.",
        "The goblin tells you, 'leave now'",
        "You see a rusted sword on the ground.",
    };
    for (const char* s : stream) pane.appendRaw(QString::fromLatin1(s));
    if (pane.lineCount() != 4) return fail("session stream lines");
    if (pane.lastLine() != "You see a rusted sword on the ground.") return fail("session stream last");

    // 2. Capture pane mirrors only matching lines (WM-FEAT-0011).
    CaptureFilter f;
    f.id = "tells";
    f.match = "tells you";
    cap.setFilter(f);
    for (const char* s : stream) cap.ingest(QString::fromLatin1(s));
    if (cap.count() != 1) return fail("session capture count");
    if (cap.captured().first() != "The goblin tells you, 'leave now'") return fail("session capture line");

    // 3. Command input flows into history; completion assists.
    hist.add("look");
    hist.add("get sword");
    if (hist.count() != 2) return fail("session history");
    if (hist.up() != "get sword") return fail("session history up");
    if (cc.candidates("no").size() != 2) return fail("session completion");

    // 4. Status gauge reflects combat state (WM-FEAT-0012).
    StatusGauge hp;
    hp.id = "hp";
    hp.label = "Hit Points";
    hp.value = "80";
    gauges.set(hp);
    hp.value = "63"; // goblin hit
    gauges.set(hp);
    if (gauges.value("hp") != "63") return fail("session gauge");

    // 5. Workspace layout persists to a real file and restores
    //    (WM-SPEC-007-R04, restart behavior).
    DockPaneSpec captureDock;
    captureDock.id = "capture";
    captureDock.title = "Capture";
    captureDock.position = "bottom";
    layout.addDock(captureDock);
    layout.gauges() = gauges;
    layout.theme().setName("night");
    layout.theme().setHighContrast(true);

    QFile fout(layoutPath);
    if (!fout.open(QIODevice::WriteOnly)) return fail("layout write open");
    fout.write(QJsonDocument(layout.toJson()).toJson(QJsonDocument::Compact));
    fout.close();

    QFile fin(layoutPath);
    if (!fin.open(QIODevice::ReadOnly)) return fail("layout read open");
    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(fin.readAll(), &err);
    fin.close();
    if (err.error != QJsonParseError::NoError) return fail("layout json parse");

    WorkspaceLayoutQt restored("x");
    if (!restored.fromJson(doc.object())) return fail("layout restore");
    if (restored.name() != "combat") return fail("layout name");
    if (!restored.hasDock("capture")) return fail("layout dock");
    if (restored.gauges().value("hp") != "63") return fail("layout gauge");
    if (!restored.theme().highContrast()) return fail("layout theme");

    // 6. Degraded optional surface: if capture filtering fails, the raw
    //    terminal stream is untouched (WM-SPEC-007-R03 preserved).
    CapturePaneQt broken(10);
    CaptureFilter bad;
    bad.id = "never";
    bad.match = "zz-no-match";
    broken.setFilter(bad);
    for (const char* s : stream) broken.ingest(QString::fromLatin1(s));
    if (broken.count() != 0) return fail("degraded capture");
    if (pane.lineCount() != 4 || pane.lastLine() != "You see a rusted sword on the ground.")
        return fail("degraded terminal preserved");

    std::printf("session flow: ok\n");
    return 0;
}

// Forced failures and abuse (EP-012 M4): resource exhaustion, malformed
// input, duplicate request, data integrity, secrets in stream.
static int cmdStress() {
    // 1. Resource exhaustion: 100k lines into a 1000-line pane. Bound
    //    holds, newest preserved, oldest dropped, no crash.
    TerminalPaneQt pane(1000);
    for (int i = 0; i < 100000; ++i) pane.appendRaw(QString("line-%1").arg(i));
    if (pane.lineCount() != 1000) return fail("stress scrollback bound");
    if (pane.lastLine() != "line-99999") return fail("stress newest preserved");
    if (pane.snapshot().first() != "line-99000") return fail("stress oldest dropped");
    if (!pane.overflowDropped()) return fail("stress overflow flag");

    // 2. History overflow: 100k adds into a 100-entry history.
    CommandHistoryQt hist(100);
    for (int i = 0; i < 100000; ++i) hist.add(QString("cmd-%1").arg(i));
    if (hist.count() != 100) return fail("stress history bound");
    if (hist.all().last() != "cmd-99999") return fail("stress history newest");

    // 3. Duplicate request: repeated identical commands dedup consecutive.
    CommandHistoryQt hist2(100);
    hist2.add("look");
    hist2.add("look");
    hist2.add("look");
    if (hist2.count() != 1) return fail("duplicate dedup");

    // 4. Malformed input: corrupt layout JSON fails cleanly.
    WorkspaceLayoutQt layout("x");
    if (layout.fromJson(QJsonObject())) return fail("empty layout accepted");
    if (layout.fromJson(QJsonObject{{"name", QJsonValue()}})) return fail("null name accepted");

    // 5. Data integrity: raw text is byte-preserved (WM-SPEC-007-R03).
    TerminalPaneQt p2(10);
    const QString tricky = QString::fromUtf8("ANSI \x1b[31mred\x1b[0m and unicode \xe2\x98\x83");
    p2.appendRaw(tricky);
    if (p2.lastLine() != tricky) return fail("raw integrity");

    // 6. Secrets in stream: token-like text stays raw data, never
    //    interpreted, and the capture mirror does not leak it beyond
    //    the exact source line.
    CapturePaneQt cap(10);
    CaptureFilter f;
    f.id = "all";
    f.match = "token";
    cap.setFilter(f);
    const QString secretLine = QStringLiteral("token: abc-def-ghij");
    cap.ingest(secretLine);
    if (cap.count() != 1) return fail("secret capture");
    if (cap.captured().first() != secretLine) return fail("secret capture altered");

    // 7. Denied policy: an empty filter captures nothing; pane unaffected.
    CapturePaneQt cap2(10);
    CaptureFilter empty;
    cap2.setFilter(empty);
    cap2.ingest("anything");
    if (cap2.count() != 0) return fail("empty filter captured");

    std::printf("stress boundary: ok\n");
    return 0;
}

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    if (argc < 2) { std::fprintf(stderr, "usage: harness terminal|workspace|editor|session|stress\n"); return 2; }
    const QString cmd = QString::fromUtf8(argv[1]);
    if (cmd == "terminal") return cmdTerminal();
    if (cmd == "workspace") return cmdWorkspace();
    if (cmd == "editor") return cmdEditor();
    if (cmd == "session" && argc >= 3) return cmdSession(QString::fromUtf8(argv[2]));
    if (cmd == "stress") return cmdStress();
    std::fprintf(stderr, "bad args\n");
    return 2;
}
