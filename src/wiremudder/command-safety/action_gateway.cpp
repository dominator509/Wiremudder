// WireMudder command-safety gateway (Qt layer).
#include "action_gateway.h"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QRegularExpression>

namespace wiremudder {

QString actionSourceName(ActionSource s)
{
    switch (s) {
    case ActionSource::Ai:
        return "ai";
    case ActionSource::Autopilot:
        return "autopilot";
    case ActionSource::Voice:
        return "voice";
    case ActionSource::Macro:
        return "macro";
    case ActionSource::Trigger:
        return "trigger";
    case ActionSource::Script:
        return "script";
    case ActionSource::Plugin:
        return "plugin";
    case ActionSource::Headless:
        return "headless";
    case ActionSource::CrossSession:
        return "cross-session";
    }
    return "unknown";
}

QVector<ActionSource> allActionSources()
{
    return {ActionSource::Ai,
            ActionSource::Autopilot,
            ActionSource::Voice,
            ActionSource::Macro,
            ActionSource::Trigger,
            ActionSource::Script,
            ActionSource::Plugin,
            ActionSource::Headless,
            ActionSource::CrossSession};
}

QString riskTierName(RiskTier t)
{
    switch (t) {
    case RiskTier::Safe:
        return "safe";
    case RiskTier::Standard:
        return "standard";
    case RiskTier::Risky:
        return "risky";
    case RiskTier::Destructive:
        return "destructive";
    }
    return "standard";
}

bool riskTierRequiresConfirmation(RiskTier t)
{
    return t == RiskTier::Risky || t == RiskTier::Destructive;
}

QString denialReasonName(DenialReason r)
{
    switch (r) {
    case DenialReason::EmergencyStop:
        return "emergency-stop";
    case DenialReason::NotConnected:
        return "not-connected";
    case DenialReason::RoutingUnstable:
        return "routing-unstable";
    case DenialReason::InjectionFlagged:
        return "injection-flagged";
    case DenialReason::DeniedByPolicy:
        return "denied-by-policy";
    case DenialReason::AutomationDisabled:
        return "automation-disabled";
    case DenialReason::Pacing:
        return "pacing";
    case DenialReason::QueueFull:
        return "queue-full";
    }
    return "unknown";
}

static bool validateArgs(const QString& policy, const QStringList& args, QString* reason)
{
    if (policy == "any") {
        *reason = "ok";
        return true;
    }
    if (policy.startsWith("eq:")) {
        const QString v = policy.mid(3);
        if (args.size() == 1 && args[0] == v) {
            *reason = "ok";
            return true;
        }
        *reason = QString("expected argument equal to %1").arg(v);
        return false;
    }
    if (policy.startsWith("min:")) {
        const int n = policy.mid(4).toInt();
        if (args.size() >= n) {
            *reason = "ok";
            return true;
        }
        *reason = QString("expected at least %1 arguments").arg(n);
        return false;
    }
    if (policy.startsWith("max:")) {
        const int n = policy.mid(4).toInt();
        if (args.size() <= n) {
            *reason = "ok";
            return true;
        }
        *reason = QString("expected at most %1 arguments").arg(n);
        return false;
    }
    *reason = "unsupported argument policy";
    return false;
}

static bool looksDestructive(const QString& command, const QStringList& args)
{
    const QString joined = (command + " " + args.join(" ")).toLower();
    static const QStringList keys = {"kill", "quit", "quit!", "delete", "drop all", "sacrifice", "sell all", "give all"};
    for (const QString& k : keys) {
        if (joined.contains(k))
            return true;
    }
    return false;
}

CommandPolicy CommandDatabaseQt::evaluate(const QString& command, const QStringList& args) const
{
    for (const CommandRule& rule : m_rules) {
        if (rule.command != command)
            continue;
        if (rule.deny) {
            return CommandPolicy{command, rule.tier, true, false, false, "denied by command database"};
        }
        QString reason;
        const bool argOk = validateArgs(rule.argPolicy, args, &reason);
        const bool confirm = riskTierRequiresConfirmation(rule.tier) && !rule.allowlisted;
        return CommandPolicy{command, rule.tier, false, confirm, argOk, reason};
    }
    const bool destructive = looksDestructive(command, args);
    return CommandPolicy{command, destructive ? RiskTier::Risky : RiskTier::Standard, false, destructive, true, "unknown command; standard tier"};
}

bool HumanTempoQt::shouldSend(quint64 nowMs, quint64* waitMs)
{
    if (nowMs - m_burstStartMs >= m_burstWindowMs) {
        m_burstStartMs = nowMs;
        m_burstCount = 0;
        if (m_lastSendMs > 0 && nowMs - m_lastSendMs < m_minIntervalMs) {
            if (waitMs)
                *waitMs = m_minIntervalMs - (nowMs - m_lastSendMs);
            return false;
        }
    }
    if (m_burstCount >= m_maxBurst) {
        if (waitMs)
            *waitMs = m_burstWindowMs - (nowMs - m_burstStartMs);
        return false;
    }
    m_lastSendMs = nowMs;
    m_burstCount += 1;
    if (waitMs)
        *waitMs = 0;
    return true;
}

QJsonObject ActionProposal::toJson() const
{
    QJsonObject o;
    o.insert("id", id);
    o.insert("source", actionSourceName(source));
    o.insert("original_suggestion", originalSuggestion);
    o.insert("normalized_command", normalizedCommand);
    QJsonArray argsArr;
    for (const QString& a : args)
        argsArr.append(a);
    o.insert("args", argsArr);
    o.insert("risk_tier", riskTierName(riskTier));
    o.insert("requires_confirmation", requiresConfirmation);
    o.insert("created_ms", qint64(createdMs));
    return o;
}

QJsonObject ActionAuditEntry::toJson() const
{
    QJsonObject o;
    o.insert("at_ms", qint64(atMs));
    o.insert("proposal_id", proposalId);
    o.insert("source", actionSourceName(source));
    o.insert("original_suggestion", originalSuggestion);
    o.insert("normalized_command", normalizedCommand);
    o.insert("risk_tier", riskTierName(riskTier));
    o.insert("required_approval", requiredApproval);
    o.insert("pacing_decision", pacingDecision);
    o.insert("final_result", finalResult);
    return o;
}

bool VisibleQueueQt::push(const QueueEntry& entry)
{
    if (m_entries.size() >= m_capacity)
        return false;
    m_entries.append(entry);
    return true;
}

int VisibleQueueQt::cancelAll()
{
    const int n = m_entries.size();
    m_entries.clear();
    return n;
}

bool VisibleQueueQt::remove(const QString& proposalId)
{
    const int before = m_entries.size();
    for (int i = m_entries.size() - 1; i >= 0; --i) {
        if (m_entries[i].proposalId == proposalId)
            m_entries.removeAt(i);
    }
    return m_entries.size() != before;
}

ActionGatewayQt::ActionGatewayQt(const CommandDatabaseQt& db, const HumanTempoQt& tempo, int queueCapacity)
: m_db(db)
, m_tempo(tempo)
, m_queue(queueCapacity)
{
}

bool ActionGatewayQt::propose(ActionSource source, const QString& suggestion, ActionProposal* out, QString* err)
{
    const QString trimmed = suggestion.trimmed();
    if (trimmed.isEmpty()) {
        if (err)
            *err = "empty suggestion";
        return false;
    }
    if (trimmed.size() > 1024) {
        if (err)
            *err = "oversized suggestion";
        return false;
    }
    if (!m_db.isReady()) {
        if (err)
            *err = "command database unavailable";
        return false;
    }
    QString body = trimmed;
    while (body.startsWith('/'))
        body.remove(0, 1);
    const QStringList parts = body.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
    if (parts.isEmpty()) {
        if (err)
            *err = "unknown intent";
        return false;
    }
    const QString cmd = parts[0].toLower();
    const QStringList args = parts.mid(1);
    const CommandPolicy policy = m_db.evaluate(cmd, args);
    m_seq += 1;
    ActionProposal p;
    p.id = QString("ap-%1").arg(m_seq, 6, 10, QLatin1Char('0'));
    p.source = source;
    p.originalSuggestion = suggestion;
    p.normalizedCommand = cmd;
    p.args = args;
    p.riskTier = policy.tier;
    p.requiresConfirmation = policy.requiresConfirmation;
    p.createdMs = quint64(QDateTime::currentMSecsSinceEpoch());
    *out = p;
    if (err)
        *err = QString();
    return true;
}

GateDecision ActionGatewayQt::evaluate(const ActionProposal& proposal, const GateContext& ctx) const
{
    if (m_emergencyStop.blocks())
        return GateDecision::Denied;
    if (!ctx.connected)
        return GateDecision::Denied;
    if (!ctx.profileAutomationEnabled)
        return GateDecision::Denied;
    if (ctx.injectionFlagged)
        return GateDecision::Denied;
    if (!ctx.routingStable)
        return GateDecision::Denied;
    const CommandPolicy policy = m_db.evaluate(proposal.normalizedCommand, proposal.args);
    if (policy.denied || !policy.argOk)
        return GateDecision::Denied;
    if (proposal.requiresConfirmation || policy.requiresConfirmation) {
        return GateDecision::NeedsConfirmation;
    }
    return GateDecision::Approved;
}

ActionAuditEntry ActionGatewayQt::makeAudit(const ActionProposal& p, const QString& result, const QString& detail) const
{
    ActionAuditEntry e;
    e.atMs = quint64(QDateTime::currentMSecsSinceEpoch());
    e.proposalId = p.id;
    e.source = p.source;
    e.originalSuggestion = p.originalSuggestion;
    e.normalizedCommand = p.normalizedCommand;
    e.riskTier = p.riskTier;
    e.requiredApproval = p.requiresConfirmation;
    e.pacingDecision = detail;
    e.finalResult = result;
    return e;
}

bool ActionGatewayQt::approveAndSend(const ActionProposal& proposal, const GateContext& ctx, const std::function<QString(const QString&)>& send, QString* result, QString* err)
{
    const GateDecision d = evaluate(proposal, ctx);
    if (d == GateDecision::Denied) {
        m_audit.append(makeAudit(proposal, "denied", "policy"));
        if (result)
            *result = "denied";
        if (err)
            *err = QString();
        return true;
    }
    if (d == GateDecision::NeedsConfirmation) {
        m_audit.append(makeAudit(proposal, "needs-confirmation", ""));
        if (result)
            *result = "needs-confirmation";
        if (err)
            *err = QString();
        return true;
    }
    quint64 waitMs = 0;
    if (!m_tempo.shouldSend(quint64(QDateTime::currentMSecsSinceEpoch()), &waitMs)) {
        m_audit.append(makeAudit(proposal, "paced", QString("wait %1ms").arg(waitMs)));
        if (result)
            *result = QString("paced:%1").arg(waitMs);
        if (err)
            *err = QString();
        return true;
    }
    const QString sendResult = send(proposal.normalizedCommand);
    m_audit.append(makeAudit(proposal, "sent", sendResult));
    if (result)
        *result = sendResult;
    if (err)
        *err = QString();
    return true;
}

bool ActionGatewayQt::queueEntry(const ActionProposal& proposal, QString* err)
{
    QueueEntry e;
    e.proposalId = proposal.id;
    e.source = proposal.source;
    e.originalSuggestion = proposal.originalSuggestion;
    e.normalizedCommand = proposal.normalizedCommand;
    e.riskTier = proposal.riskTier;
    e.requiredApproval = proposal.requiresConfirmation;
    e.pacingDecision = "pending";
    e.status = "awaiting-approval";
    if (!m_queue.push(e)) {
        if (err)
            *err = "queue full";
        return false;
    }
    if (err)
        *err = QString();
    return true;
}

void ActionGatewayQt::engageEmergencyStop()
{
    const int cancelled = m_queue.cancelAll();
    m_emergencyStop.engage();
    ActionAuditEntry e;
    e.atMs = quint64(QDateTime::currentMSecsSinceEpoch());
    e.proposalId = "*";
    e.source = ActionSource::Autopilot;
    e.finalResult = QString("cancelled %1 queued").arg(cancelled);
    e.pacingDecision = "emergency-stop";
    m_audit.append(e);
}

void ActionGatewayQt::releaseEmergencyStop()
{
    m_emergencyStop.release();
}

} // namespace wiremudder
