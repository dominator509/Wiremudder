// WireMudder Power Tools Pane Harness (EP-022 M3).
//
// Real compiled harness: links the actual power_tools_boundary.cpp surface
// and exercises the user-visible flow: loading -> ready with Macro Forge
// drafts (preview-only until approved), Trigger Test Lab fixtures, AI
// Debugger diagnoses (evidence-cited, never self-certifying, no gate
// editing), privacy-scoped variable inspection, event timeline, and
// budget samples with slow offenders. Proves the pane compiles into a
// real binary and behaves deterministically.
#include "src/wiremudder/ui/power-tools/power_tools_boundary.h"
#include <cstdio>

using wiremudder::ui::PowerToolsPaneQt;
using wiremudder::ui::PowerToolsPaneState;
using wiremudder::ui::AutomationDraftQt;
using wiremudder::ui::ReplayFixtureQt;
using wiremudder::ui::AiDiagnosisQt;
using wiremudder::ui::InspectedVariableQt;
using wiremudder::ui::BudgetSampleQt;

static int failures = 0;
#define CHECK(cond) do { if (!(cond)) { std::printf("HARNESS FAIL: %s (line %d)\n", #cond, __LINE__); ++failures; } } while (0)

int main() {
    PowerToolsPaneQt pane;
    CHECK(pane.isPassive());
    CHECK(!pane.canSendCommand());
    CHECK(!pane.canEditGates());
    CHECK(pane.state() == PowerToolsPaneState::Unavailable);

    // Loading -> Ready.
    pane.setState(PowerToolsPaneState::Loading);
    CHECK(pane.stateLabel() == QStringLiteral("loading"));
    pane.setState(PowerToolsPaneState::Ready);
    CHECK(pane.stateLabel() == QStringLiteral("ready"));

    // Macro Forge: preview-only draft, disabled until approved.
    AutomationDraftQt draft;
    draft.id = QStringLiteral("macro-heal");
    draft.kind = QStringLiteral("macro");
    draft.name = QStringLiteral("heal");
    draft.body = QStringLiteral("send(\"cure light\")");
    draft.approved = false;
    draft.previewOnly = true;
    QVector<AutomationDraftQt> drafts;
    drafts.append(draft);
    pane.setDrafts(drafts);
    CHECK(pane.draftCount() == 1);
    CHECK(pane.drafts()[0].previewOnly);
    CHECK(!pane.drafts()[0].approved);

    // Trigger Test Lab: fixture with deterministic replay summary.
    ReplayFixtureQt fx;
    fx.id = QStringLiteral("fixture-crossroads");
    fx.name = QStringLiteral("crossroads guard");
    fx.steps = 2;
    fx.matched = 2;
    fx.lastFinished = true;
    QVector<ReplayFixtureQt> fixtures;
    fixtures.append(fx);
    pane.setFixtures(fixtures);
    CHECK(pane.fixtureCount() == 1);
    CHECK(pane.fixtures()[0].lastFinished);

    // AI Debugger: cites evidence, never self-certifies, no gate edit.
    AiDiagnosisQt diag;
    diag.id = QStringLiteral("diag-1");
    diag.evidence.append(QStringLiteral("line 1: guard blocked north"));
    diag.hypothesis = QStringLiteral("trigger fires late");
    diag.patchPlan = QStringLiteral("raise budget");
    diag.selfCertified = false;
    diag.gateEditable = false;
    QVector<AiDiagnosisQt> diagnoses;
    diagnoses.append(diag);
    pane.setDiagnoses(diagnoses);
    CHECK(pane.diagnosisCount() == 1);
    CHECK(!pane.diagnoses()[0].selfCertified);
    CHECK(!pane.diagnoses()[0].gateEditable);
    CHECK(pane.diagnoses()[0].evidence.size() == 1);

    // Variable inspection: private values redacted on the surface.
    InspectedVariableQt gold;
    gold.name = QStringLiteral("gold");
    gold.scope = QStringLiteral("public");
    gold.value = QStringLiteral("42");
    InspectedVariableQt pass;
    pass.name = QStringLiteral("password");
    pass.scope = QStringLiteral("private");
    pass.value = QStringLiteral("<redacted>");
    QVector<InspectedVariableQt> vars;
    vars.append(gold);
    vars.append(pass);
    pane.setVariables(vars);
    CHECK(pane.variableCount() == 2);
    CHECK(pane.variables()[1].value == QStringLiteral("<redacted>"));

    // Performance statistics: budget sample with slow offender.
    BudgetSampleQt sample;
    sample.runId = QStringLiteral("r1");
    sample.kind = QStringLiteral("trigger");
    sample.name = QStringLiteral("guard");
    sample.elapsedMs = 150;
    sample.budgetMs = 100;
    sample.overBudget = true;
    QVector<BudgetSampleQt> samples;
    samples.append(sample);
    pane.setBudgetSamples(samples);
    CHECK(pane.budgetSampleCount() == 1);
    CHECK(pane.budgetSamples()[0].overBudget);

    // User intent recorded, not executed: approval is a request flag.
    pane.requestApproveDraft(QStringLiteral("macro-heal"));
    CHECK(pane.approveDraftRequested() == QStringLiteral("macro-heal"));

    // Non-ready state clears the pane (SPEC-025 deterministic behavior).
    pane.setState(PowerToolsPaneState::Denied);
    CHECK(pane.stateLabel() == QStringLiteral("denied"));
    CHECK(pane.draftCount() == 0);
    CHECK(pane.variableCount() == 0);

    if (failures == 0) {
        std::printf("power-tools pane harness: ok\n");
        return 0;
    }
    std::printf("power-tools pane harness: FAIL (%d checks)\n", failures);
    return 1;
}
