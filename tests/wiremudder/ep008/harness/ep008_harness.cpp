// EP-008 M3 test harness: exercises the real Qt command-safety layer.
// Subcommands: policy | gateway | estop | oracle
#include <QCoreApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

#include <cstdio>

#include "src/wiremudder/command-safety/action_gateway.h"

using namespace wiremudder;

static int fail(const char* msg) {
    std::fprintf(stderr, "FAIL: %s\n", msg);
    return 1;
}

static ActionSource actionSourceFromName(const QString& name);
static QString gateDecisionName(GateDecision d);

static CommandDatabaseQt makeDb() {
    CommandDatabaseQt db("midkemia");
    db.addRule(CommandRule{"say", RiskTier::Safe, false, false, "any"});
    db.addRule(CommandRule{"tell", RiskTier::Standard, false, false, "any"});
    db.addRule(CommandRule{"kill", RiskTier::Destructive, false, false, "any"});
    db.addRule(CommandRule{"quit", RiskTier::Destructive, true, false, "any"});
    db.addRule(CommandRule{"give", RiskTier::Risky, false, false, "min:2"});
    db.addRule(CommandRule{"drop all", RiskTier::Destructive, false, true, "any"});
    return db;
}

static int cmdPolicy() {
    const CommandDatabaseQt db = makeDb();

    // Deterministic tiers and confirmations.
    if (db.evaluate("say", {"hi"}).requiresConfirmation) return fail("say confirm");
    if (db.evaluate("tell", {"bob", "hi"}).requiresConfirmation) return fail("tell confirm");
    if (!db.evaluate("kill", {"orc"}).requiresConfirmation) return fail("kill not confirmed");
    if (db.evaluate("drop all", {}).requiresConfirmation) return fail("allowlist ignored");
    if (!db.evaluate("quit", {}).denied) return fail("deny not enforced");

    // Argument validation.
    if (!db.evaluate("give", {"bob", "sword"}).argOk) return fail("give args ok");
    if (db.evaluate("give", {"bob"}).argOk) return fail("give args bad accepted");

    // Unknown commands are never high-confidence shortcuts.
    const CommandPolicy unknown = db.evaluate("frobnicate", {"x"});
    if (unknown.tier != RiskTier::Standard) return fail("unknown tier");

    // Human-Tempo: burst of 3 then wait; window reset.
    HumanTempoQt tempo(1000, 3, 5000);
    quint64 wait = 999;
    if (!tempo.shouldSend(0, &wait)) return fail("tempo first");
    if (!tempo.shouldSend(10, &wait)) return fail("tempo second");
    if (!tempo.shouldSend(20, &wait)) return fail("tempo third");
    if (tempo.shouldSend(30, &wait)) return fail("tempo burst not exhausted");
    if (!tempo.shouldSend(5000, &wait)) return fail("tempo window reset");

    std::printf("harness policy: ok\n");
    return 0;
}

static int cmdGateway() {
    ActionGatewayQt gw(makeDb(), HumanTempoQt(0, 1000, 100000), 16);

    // All nine non-manual sources enter the gate.
    for (ActionSource s : allActionSources()) {
        ActionProposal p;
        QString err;
        if (!gw.propose(s, "say hello", &p, &err)) return fail("propose source");
        if (p.source != s) return fail("source mismatch");
    }

    // Gate context verification.
    ActionProposal p;
    QString err;
    gw.propose(ActionSource::Ai, "say hello", &p, &err);
    GateContext ctx = GateContext::ready();
    if (gw.evaluate(p, ctx) != GateDecision::Approved) return fail("ready approved");
    ctx.connected = false;
    if (gw.evaluate(p, ctx) != GateDecision::Denied) return fail("disconnected not denied");
    ctx.connected = true;
    ctx.profileAutomationEnabled = false;
    if (gw.evaluate(p, ctx) != GateDecision::Denied) return fail("automation disabled");

    // Destructive requires confirmation; denied never sends.
    ActionProposal kill;
    gw.propose(ActionSource::Macro, "kill orc", &kill, &err);
    if (!kill.requiresConfirmation) return fail("kill not confirmed");
    if (gw.evaluate(kill, GateContext::ready()) != GateDecision::NeedsConfirmation) {
        return fail("kill not needs-confirmation");
    }
    ActionProposal quit;
    gw.propose(ActionSource::Script, "quit", &quit, &err);
    if (gw.evaluate(quit, GateContext::ready()) != GateDecision::Denied) {
        return fail("quit not denied");
    }

    // Injection flag blocks.
    ActionProposal inj;
    gw.propose(ActionSource::Voice, "say hi", &inj, &err);
    GateContext injCtx = GateContext::ready();
    injCtx.injectionFlagged = true;
    if (gw.evaluate(inj, injCtx) != GateDecision::Denied) return fail("injection not blocked");

    // Queue bounded (capacity 2 gateway).
    ActionGatewayQt smallGw(makeDb(), HumanTempoQt(0, 1000, 100000), 2);
    ActionProposal a, b, c;
    smallGw.propose(ActionSource::Macro, "say a", &a, &err);
    smallGw.propose(ActionSource::Macro, "say b", &b, &err);
    smallGw.propose(ActionSource::Macro, "say c", &c, &err);
    if (!smallGw.queueEntry(a, &err)) return fail("queue a");
    if (!smallGw.queueEntry(b, &err)) return fail("queue b");
    if (smallGw.queueEntry(c, &err)) return fail("queue c accepted (capacity 2)");
    if (smallGw.queue().len() != 2) return fail("queue length");

    // Audit complete and replayable.
    ActionProposal sendable;
    gw.propose(ActionSource::Voice, "say hello", &sendable, &err);
    QString result;
    gw.approveAndSend(sendable, GateContext::ready(),
                      [](const QString& cmd) { return QString("sent:%1").arg(cmd); },
                      &result, &err);
    if (!result.startsWith("sent:")) return fail("send result");
    if (gw.auditLog().isEmpty()) return fail("audit empty");

    std::printf("harness gateway: ok\n");
    return 0;
}

static int cmdEstop() {
    ActionGatewayQt gw(makeDb(), HumanTempoQt(0, 1000, 100000), 16);
    QString err;

    ActionProposal p1, p2;
    gw.propose(ActionSource::Trigger, "say one", &p1, &err);
    gw.propose(ActionSource::Macro, "say two", &p2, &err);
    gw.queueEntry(p1, &err);
    gw.queueEntry(p2, &err);
    if (gw.queue().len() != 2) return fail("queue not filled");

    gw.engageEmergencyStop();
    if (!gw.emergencyStopEngaged()) return fail("estop not engaged");
    if (gw.queue().len() != 0) return fail("estop did not cancel queue");

    ActionProposal p3;
    gw.propose(ActionSource::Trigger, "say three", &p3, &err);
    if (gw.evaluate(p3, GateContext::ready()) != GateDecision::Denied) {
        return fail("estop did not block new proposals");
    }
    // Cancellation audited.
    bool found = false;
    for (const auto& e : gw.auditLog()) {
        if (e.finalResult.contains("cancelled 2")) found = true;
    }
    if (!found) return fail("estop cancellation not audited");

    gw.releaseEmergencyStop();
    if (gw.emergencyStopEngaged()) return fail("estop not released");
    if (gw.evaluate(p3, GateContext::ready()) != GateDecision::Approved) {
        return fail("post-release evaluate");
    }

    std::printf("harness estop: ok\n");
    return 0;
}

// Oracle: emit the gate/policy matrix for cross-check with Rust.
static int cmdOracle() {
    const CommandDatabaseQt db = makeDb();
    QJsonArray matrix;
    auto entry = [&](const char* id, const QString& cmd, const QStringList& args) {
        const CommandPolicy p = db.evaluate(cmd, args);
        QJsonObject o;
        o.insert("id", id);
        o.insert("command", cmd);
        o.insert("tier", riskTierName(p.tier));
        o.insert("denied", p.denied);
        o.insert("requires_confirmation", p.requiresConfirmation);
        o.insert("arg_ok", p.argOk);
        matrix.append(o);
    };
    entry("say", "say", {"hi"});
    entry("tell", "tell", {"bob", "hi"});
    entry("kill", "kill", {"orc"});
    entry("quit", "quit", {});
    entry("give-bad", "give", {"bob"});
    entry("give-ok", "give", {"bob", "sword"});
    entry("drop-all", "drop all", {});
    entry("unknown", "frobnicate", {"x"});

    // Gate matrix on the same scenarios.
    ActionGatewayQt gw(db, HumanTempoQt(0, 1000, 100000), 16);
    QJsonArray gates;
    auto gate = [&](const char* src, const QString& suggestion, const GateContext& ctx) {
        ActionProposal p;
        QString err;
        gw.propose(actionSourceFromName(src), suggestion, &p, &err);
        QJsonObject o;
        o.insert("source", src);
        o.insert("suggestion", suggestion);
        o.insert("decision", gateDecisionName(gw.evaluate(p, ctx)));
        o.insert("tier", riskTierName(p.riskTier));
        o.insert("requires_confirmation", p.requiresConfirmation);
        gates.append(o);
    };
    gate("ai", "say hello", GateContext::ready());
    gate("macro", "kill orc", GateContext::ready());
    gate("script", "quit", GateContext::ready());
    GateContext dis = GateContext::ready();
    dis.connected = false;
    gate("trigger", "say hi", dis);

    const QJsonObject out{{"matrix", matrix}, {"gates", gates}};
    std::printf("%s\n", QJsonDocument(out).toJson(QJsonDocument::Compact).constData());
    return 0;
}

static ActionSource actionSourceFromName(const QString& name) {
    if (name == "autopilot") return ActionSource::Autopilot;
    if (name == "voice") return ActionSource::Voice;
    if (name == "macro") return ActionSource::Macro;
    if (name == "trigger") return ActionSource::Trigger;
    if (name == "script") return ActionSource::Script;
    if (name == "plugin") return ActionSource::Plugin;
    if (name == "headless") return ActionSource::Headless;
    if (name == "cross-session") return ActionSource::CrossSession;
    return ActionSource::Ai;
}

static QString gateDecisionName(GateDecision d) {
    switch (d) {
        case GateDecision::Approved: return "Approved";
        case GateDecision::NeedsConfirmation: return "NeedsConfirmation";
        case GateDecision::Denied: return "Denied";
        case GateDecision::Paused: return "Paused";
        case GateDecision::Queued: return "Queued";
    }
    return "Unknown";
}

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    const QString cmd = argc > 1 ? QString::fromUtf8(argv[1]) : QString();
    if (cmd == "policy") return cmdPolicy();
    if (cmd == "gateway") return cmdGateway();
    if (cmd == "estop") return cmdEstop();
    if (cmd == "oracle") return cmdOracle();
    std::fprintf(stderr, "usage: %s policy|gateway|estop|oracle\n", argv[0]);
    return 2;
}
