// WireMudder Assistance Boundary (EP-020 M3)
//
// Quest Compass, Tactical HUD, and Personal Narrator pane surface
// (WM-FEAT-0054, WM-FEAT-0055, WM-FEAT-0056, WM-FEAT-0183, WM-FEAT-0184;
// WM-SPEC-012-R06, WM-SPEC-012-R07, WM-SPEC-015-R06). Shows cited quest
// state with visible uncertainty, the bounded tactical snapshot, and
// narrated summaries that disclose their source and redact secrets. The
// pane is a passive observer: it displays data only. It NEVER sends
// commands and has no command path of its own. Narrated text cannot
// trigger terminal input; summaries are read-only.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded, Canceled,
// Unavailable, Error. Optional failure preserves manual text gameplay.
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

enum class AssistancePaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// One cited quest clue (WM-SPEC-012-R06).
struct QuestClueQt {
    QString text;
    QString citedFrom; // source location for the clue
};

// One tracked quest with visible uncertainty.
struct QuestEntryQt {
    QString questId;
    QString title;
    QString state; // observed | inferred | completed | failed | user-corrected
    QString uncertainty; // empty unless inferred/user-corrected
    QVector<QuestClueQt> clues;
};

// Bounded tactical snapshot (WM-SPEC-012-R07).
struct TacticalSnapshotQt {
    QString room;
    int healthPct = 0;
    int energyPct = 0;
    QString threatLevel;
    QStringList nearbyEntities;
    quint64 atMs = 0;
};

// Narrator summary with source disclosure and privacy flag.
struct NarratorSummaryQt {
    QString text;
    QString source; // quest | tactical | help | setup | combat
    QStringList cites;
    bool redacted = false;
    quint64 atMs = 0;
};

// Quest Compass, Tactical HUD, and Personal Narrator pane. Model-side Qt
// surface; no QWidget dependency. Passive: never sends commands, never
// writes to terminal, never triggers input.
class AssistancePaneQt {
public:
    explicit AssistancePaneQt();

    AssistancePaneState state() const { return state_; }
    void setState(AssistancePaneState s);
    QString stateLabel() const;

    // Quest Compass (WM-FEAT-0054, WM-SPEC-012-R06).
    void setQuests(const QVector<QuestEntryQt>& q) { quests_ = q; }
    int questCount() const { return quests_.size(); }
    const QVector<QuestEntryQt>& quests() const { return quests_; }

    // Tactical HUD (WM-FEAT-0055, WM-SPEC-012-R07).
    void setTactical(const TacticalSnapshotQt& s) { tactical_ = s; hasTactical_ = true; }
    void clearTactical() { hasTactical_ = false; tactical_ = TacticalSnapshotQt(); }
    bool hasTactical() const { return hasTactical_; }
    const TacticalSnapshotQt& tactical() const { return tactical_; }

    // Personal Narrator (WM-FEAT-0056, WM-FEAT-0183, WM-FEAT-0184).
    void setSummaries(const QVector<NarratorSummaryQt>& s) { summaries_ = s; }
    int summaryCount() const { return summaries_.size(); }
    const QVector<NarratorSummaryQt>& summaries() const { return summaries_; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No command path exists on this boundary (narrator never sends commands).
    bool canSendCommand() const { return false; }

    void clear() {
        quests_.clear();
        hasTactical_ = false;
        tactical_ = TacticalSnapshotQt();
        summaries_.clear();
        lastMessage_.clear();
    }

private:
    AssistancePaneState state_ = AssistancePaneState::Unavailable;
    QVector<QuestEntryQt> quests_;
    bool hasTactical_ = false;
    TacticalSnapshotQt tactical_;
    QVector<NarratorSummaryQt> summaries_;
    QString lastMessage_;
};

} // namespace wiremudder::ui
