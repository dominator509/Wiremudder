// EP-019 M3 E2E: Qt autopilot pane state machine (real compiled C++ harness).
//
// Exercises AutopilotPaneQt: initial state, ready with status/pending/
// allowlist data, non-ready clearing, passive observer, user-intent
// request surfaces, and no command-send path. Compiled by the M3 E2E
// test script.
#include <cassert>
#include <iostream>

#include "src/wiremudder/ui/autopilot/autopilot_boundary.h"

using namespace wiremudder::ui;

int main() {
    AutopilotPaneQt pane;

    // Initial state: unavailable, passive, no command path.
    assert(pane.state() == AutopilotPaneState::Unavailable);
    assert(pane.stateLabel() == QStringLiteral("unavailable"));
    assert(pane.isPassive());
    assert(!pane.canSendCommand());

    // Ready with full status surface.
    pane.setMode(QStringLiteral("confirm-every"));
    pane.setProfile(QStringLiteral("midkemia"));
    pane.setStaleReason(QString());
    pane.setLastActionAtMs(123456789);

    QVector<PendingActionQt> pending;
    PendingActionQt safe;
    safe.proposalId = QStringLiteral("ap-000001");
    safe.command = QStringLiteral("say hello");
    safe.requiresConfirmation = false;
    safe.status = QStringLiteral("approved-visible");
    safe.riskTier = QStringLiteral("safe");
    pending.append(safe);
    PendingActionQt destructive;
    destructive.proposalId = QStringLiteral("ap-000002");
    destructive.command = QStringLiteral("kill orc");
    destructive.requiresConfirmation = true;
    destructive.status = QStringLiteral("awaiting-confirmation");
    destructive.riskTier = QStringLiteral("destructive");
    pending.append(destructive);
    pane.setPending(pending);
    assert(pane.pendingCount() == 2);

    QStringList allowlist;
    allowlist << QStringLiteral("say") << QStringLiteral("tell");
    pane.setAllowlist(allowlist);
    assert(pane.allowlist().size() == 2);

    pane.setState(AutopilotPaneState::Ready);
    assert(pane.stateLabel() == QStringLiteral("ready"));
    assert(pane.pendingCount() == 2);

    // User intent surfaces: confirm/cancel/emergency stop are requests;
    // the pane has no command path.
    pane.requestConfirm(QStringLiteral("ap-000002"));
    assert(pane.confirmRequested() == QStringLiteral("ap-000002"));
    pane.requestCancel(QStringLiteral("ap-000001"));
    assert(pane.cancelRequested() == QStringLiteral("ap-000001"));
    pane.requestEmergencyStop();
    assert(pane.emergencyStopRequested());
    assert(!pane.canSendCommand());

    // Non-ready state clears stale data (SPEC-025) and preserves passivity.
    pane.setState(AutopilotPaneState::Denied);
    assert(pane.stateLabel() == QStringLiteral("denied"));
    assert(pane.pendingCount() == 0);
    assert(pane.isPassive());
    assert(!pane.canSendCommand());

    std::printf("E2E autopilot pane: ok\n");
    return 0;
}
