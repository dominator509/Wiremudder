// EP-018 M3 E2E: Qt soul pane state machine (real compiled C++ harness).
//
// Exercises SoulPaneQt: initial state, ready with persona/skills/
// permissions/council data, non-ready clearing, passive observer, and no
// authority grant path. Compiled by the M3 E2E test script.
#include <cassert>
#include <iostream>

#include "src/wiremudder/ui/soul/soul_boundary.h"

using namespace wiremudder::ui;

int main() {
    SoulPaneQt pane;

    // Initial state: unavailable, passive, no authority path.
    assert(pane.state() == SoulPaneState::Unavailable);
    assert(pane.stateLabel() == QStringLiteral("unavailable"));
    assert(pane.isPassive());
    assert(!pane.canGrantAuthority());

    // Ready with full data surfaces.
    pane.setSoulName(QStringLiteral("Guardian"));
    pane.setCompiledPrompt(QStringLiteral("You are Guardian. Tone: calm."));
    QStringList precedence;
    precedence << QStringLiteral("security:ok") << QStringLiteral("privacy:ok")
               << QStringLiteral("routing:ok");
    pane.setPolicyPrecedence(precedence);

    QVector<SkillRowQt> skills;
    SkillRowQt s;
    s.id = QStringLiteral("sk-map");
    s.name = QStringLiteral("map-draw");
    s.version = QStringLiteral("1.0.0");
    s.source = QStringLiteral("builtin");
    s.evaluationStatus = QStringLiteral("evaluated");
    s.enabled = true;
    skills.append(s);
    pane.setSkills(skills);

    QVector<MemoryPermissionQt> perms;
    MemoryPermissionQt p;
    p.role = QStringLiteral("mapper");
    p.memoryClass = QStringLiteral("transcript");
    p.access = QStringLiteral("deny");
    perms.append(p);
    pane.setPermissions(perms);

    QVector<CouncilRowQt> councilRows;
    CouncilRowQt c;
    c.councilId = QStringLiteral("c-1");
    c.task = QStringLiteral("proceed?");
    c.finalSynthesis = QStringLiteral("council support: support=2 oppose=1 disagreements=1");
    c.disagreements << QStringLiteral("combat risk too high");
    c.permitted = true;
    councilRows.append(c);
    pane.setCouncil(councilRows);

    pane.setState(SoulPaneState::Ready);
    assert(pane.stateLabel() == QStringLiteral("ready"));
    assert(pane.soulName() == QStringLiteral("Guardian"));
    assert(pane.skillCount() == 1);
    assert(pane.permissionCount() == 1);
    assert(pane.councilCount() == 1);
    assert(pane.policyPrecedence().size() == 3);
    assert(pane.skills().first().enabled);
    assert(pane.council().first().disagreements.size() == 1);

    // Non-ready clears data; disabled/denied/degraded/canceled/error states.
    pane.setState(SoulPaneState::Denied);
    assert(pane.stateLabel() == QStringLiteral("denied"));
    assert(pane.skillCount() == 0);
    pane.setState(SoulPaneState::Disabled);
    assert(pane.stateLabel() == QStringLiteral("disabled"));
    pane.setState(SoulPaneState::Degraded);
    assert(pane.stateLabel() == QStringLiteral("degraded"));
    pane.setState(SoulPaneState::Canceled);
    assert(pane.stateLabel() == QStringLiteral("canceled"));
    pane.setState(SoulPaneState::Error);
    assert(pane.stateLabel() == QStringLiteral("error"));
    pane.setLastMessage(QStringLiteral("soul policy override rejected"));
    assert(pane.lastMessage() == QStringLiteral("soul policy override rejected"));

    std::cout << "E2E soul pane: ok" << std::endl;
    return 0;
}
