// WireMudder Soul Boundary (EP-018 M3)
//
// Soul Studio pane surface (WM-FEAT-0043, WM-SPEC-014-R04). Holds the
// active Soul persona, its compiled-prompt preview, policy precedence,
// the Agent Skill Tree, role-scoped memory permissions, and recent council
// records. The pane is a passive observer: it displays data and never
// grants authority, installs skills, or convenes councils by itself.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded, Canceled,
// Unavailable, Error. Optional failure preserves manual text gameplay.
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

enum class SoulPaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// One skill row in the tree (WM-SPEC-014-R05).
struct SkillRowQt {
    QString id;
    QString name;
    QString version;
    QString source;
    QStringList permissions;
    QString evaluationStatus; // evaluated | pending | failed
    QString profileScope;
    bool enabled = false;
};

// One memory permission row (WM-SPEC-014-R06).
struct MemoryPermissionQt {
    QString role;
    QString memoryClass;
    QString access; // deny | read | propose | summarize | share
};

// One council record row (WM-SPEC-014-R07).
struct CouncilRowQt {
    QString councilId;
    QString task;
    QString finalSynthesis;
    QStringList disagreements;
    quint64 budgetUsdMicros = 0;
    bool permitted = false;
};

// Soul Studio pane (WM-FEAT-0043). Model-side Qt surface; no QWidget
// dependency. Passive: never grants authority, never self-modifies.
class SoulPaneQt {
public:
    explicit SoulPaneQt();

    SoulPaneState state() const { return state_; }
    void setState(SoulPaneState s);
    QString stateLabel() const;

    // Active persona.
    void setSoulName(const QString& n) { soulName_ = n; }
    QString soulName() const { return soulName_; }
    void setCompiledPrompt(const QString& p) { compiledPrompt_ = p; }
    QString compiledPrompt() const { return compiledPrompt_; }
    void setPolicyPrecedence(const QStringList& p) { policyPrecedence_ = p; }
    QStringList policyPrecedence() const { return policyPrecedence_; }

    // Skill tree.
    void setSkills(const QVector<SkillRowQt>& s) { skills_ = s; }
    int skillCount() const { return skills_.size(); }
    const QVector<SkillRowQt>& skills() const { return skills_; }

    // Memory permissions.
    void setPermissions(const QVector<MemoryPermissionQt>& p) { permissions_ = p; }
    int permissionCount() const { return permissions_.size(); }
    const QVector<MemoryPermissionQt>& permissions() const { return permissions_; }

    // Council records.
    void setCouncil(const QVector<CouncilRowQt>& c) { council_ = c; }
    int councilCount() const { return council_.size(); }
    const QVector<CouncilRowQt>& council() const { return council_; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No authority grant path exists on this boundary (obligation 6).
    bool canGrantAuthority() const { return false; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    void clear() {
        soulName_.clear();
        compiledPrompt_.clear();
        policyPrecedence_.clear();
        skills_.clear();
        permissions_.clear();
        council_.clear();
    }

private:
    SoulPaneState state_ = SoulPaneState::Unavailable;
    QString soulName_;
    QString compiledPrompt_;
    QStringList policyPrecedence_;
    QVector<SkillRowQt> skills_;
    QVector<MemoryPermissionQt> permissions_;
    QVector<CouncilRowQt> council_;
    QString lastMessage_;
};

} // namespace wiremudder::ui
