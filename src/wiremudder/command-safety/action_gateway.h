// WireMudder command-safety gateway (Qt layer, SPEC-009).
// Mirrors the wire-actions/wire-policy Rust core semantics for the
// oracle cross-check. Every non-manual source enters the same
// deterministic Action Proposal path (WM-SPEC-009-R02); manual input
// remains direct (WM-SPEC-009-R01); emergency stop is a global atomic
// state that cancels the queue and blocks new proposals
// (WM-SPEC-009-R06); every action is replayable from audit (WM-FEAT-0179).
#pragma once

#include <QJsonObject>
#include <QString>
#include <QStringList>
#include <QVector>

#include <functional>

namespace wiremudder {

constexpr int ACTION_SCHEMA_VERSION = 1;

enum class ActionSource {
    Ai,
    Autopilot,
    Voice,
    Macro,
    Trigger,
    Script,
    Plugin,
    Headless,
    CrossSession,
};

QString actionSourceName(ActionSource s);
QVector<ActionSource> allActionSources();

enum class RiskTier { Safe, Standard, Risky, Destructive };

QString riskTierName(RiskTier t);
bool riskTierRequiresConfirmation(RiskTier t);

enum class DenialReason {
    EmergencyStop,
    NotConnected,
    RoutingUnstable,
    InjectionFlagged,
    DeniedByPolicy,
    AutomationDisabled,
    Pacing,
    QueueFull,
};

QString denialReasonName(DenialReason r);

enum class GateDecision {
    Approved,
    NeedsConfirmation,
    Denied,
    Paused,
    Queued,
};

struct GateContext
{
    bool connected = true;
    bool emergencyStopEngaged = false;
    bool sourceVisible = true;
    bool profileAutomationEnabled = true;
    bool routingStable = true;
    bool injectionFlagged = false;

    static GateContext ready() { return GateContext(); }
};

struct CommandRule
{
    QString command;
    RiskTier tier = RiskTier::Standard;
    bool deny = false;
    bool allowlisted = false;
    QString argPolicy = "any";
};

struct CommandPolicy
{
    QString command;
    RiskTier tier = RiskTier::Standard;
    bool denied = false;
    bool requiresConfirmation = false;
    bool argOk = true;
    QString argReason;
};

// Per-world command database (WM-FEAT-0174).
class CommandDatabaseQt
{
public:
    CommandDatabaseQt() = default;
    explicit CommandDatabaseQt(const QString& world)
    : m_world(world)
    {
    }

    void addRule(const CommandRule& rule) { m_rules.append(rule); }
    CommandPolicy evaluate(const QString& command, const QStringList& args) const;
    bool isReady() const { return !m_world.isEmpty(); }

private:
    QString m_world;
    QVector<CommandRule> m_rules;
};

// Human-Tempo pacing (WM-SPEC-009-R07): bounded burst per window,
// inter-group cooldown. Anti-spam only.
class HumanTempoQt
{
public:
    HumanTempoQt(quint64 minIntervalMs, int maxBurst, quint64 burstWindowMs)
    : m_minIntervalMs(minIntervalMs)
    , m_maxBurst(maxBurst)
    , m_burstWindowMs(burstWindowMs)
    {
    }

    // Returns true when a send may proceed now.
    bool shouldSend(quint64 nowMs, quint64* waitMs);

private:
    quint64 m_minIntervalMs;
    int m_maxBurst;
    quint64 m_burstWindowMs;
    quint64 m_lastSendMs = 0;
    quint64 m_burstStartMs = 0;
    int m_burstCount = 0;
};

struct ActionProposal
{
    QString id;
    ActionSource source = ActionSource::Ai;
    QString originalSuggestion;
    QString normalizedCommand;
    QStringList args;
    RiskTier riskTier = RiskTier::Standard;
    bool requiresConfirmation = false;
    quint64 createdMs = 0;

    QJsonObject toJson() const;
};

struct QueueEntry
{
    QString proposalId;
    ActionSource source = ActionSource::Ai;
    QString originalSuggestion;
    QString normalizedCommand;
    RiskTier riskTier = RiskTier::Standard;
    bool requiredApproval = false;
    QString pacingDecision;
    QString status;
};

struct ActionAuditEntry
{
    quint64 atMs = 0;
    QString proposalId;
    ActionSource source = ActionSource::Ai;
    QString originalSuggestion;
    QString normalizedCommand;
    RiskTier riskTier = RiskTier::Standard;
    bool requiredApproval = false;
    QString pacingDecision;
    QString finalResult;

    QJsonObject toJson() const;
};

// Bounded visible queue (WM-SPEC-009-R08).
class VisibleQueueQt
{
public:
    explicit VisibleQueueQt(int capacity)
    : m_capacity(capacity)
    {
    }

    bool push(const QueueEntry& entry);
    int cancelAll();
    int len() const { return m_entries.size(); }
    bool remove(const QString& proposalId);
    const QVector<QueueEntry>& entries() const { return m_entries; }

private:
    int m_capacity;
    QVector<QueueEntry> m_entries;
};

// Global emergency stop (WM-SPEC-009-R06, WM-SPEC-017-R08).
class EmergencyStopQt
{
public:
    void engage() { m_engaged = true; }
    void release() { m_engaged = false; }
    bool isEngaged() const { return m_engaged; }
    bool blocks() const { return m_engaged; }

private:
    bool m_engaged = false;
};

// Deterministic Action Proposal gateway.
class ActionGatewayQt
{
public:
    ActionGatewayQt(const CommandDatabaseQt& db, const HumanTempoQt& tempo, int queueCapacity);

    // Propose: normalize a free-form suggestion. Returns false + err for
    // empty/oversized/ambiguous input (WM-SPEC-009-R10).
    bool propose(ActionSource source, const QString& suggestion, ActionProposal* out, QString* err);

    // Evaluate: full gate check (WM-SPEC-009-R03).
    GateDecision evaluate(const ActionProposal& proposal, const GateContext& ctx) const;

    // Approve and send (or pace/deny); writes the audit record.
    bool approveAndSend(const ActionProposal& proposal, const GateContext& ctx, const std::function<QString(const QString&)>& send, QString* result, QString* err);

    bool queueEntry(const ActionProposal& proposal, QString* err);
    void engageEmergencyStop();
    void releaseEmergencyStop();
    bool emergencyStopEngaged() const { return m_emergencyStop.isEngaged(); }

    const VisibleQueueQt& queue() const { return m_queue; }
    const QVector<ActionAuditEntry>& auditLog() const { return m_audit; }

private:
    CommandDatabaseQt m_db;
    HumanTempoQt m_tempo;
    VisibleQueueQt m_queue;
    EmergencyStopQt m_emergencyStop;
    QVector<ActionAuditEntry> m_audit;
    quint64 m_seq = 0;

    ActionAuditEntry makeAudit(const ActionProposal& p, const QString& result, const QString& detail) const;
};

} // namespace wiremudder
