// WireMudder character memory profile store (Qt layer, SPEC-010/017/023).
// Mirrors the wire-profiles Rust core semantics so the oracle tests can
// cross-check both implementations. Every character tab attaches to one
// persistent Character Memory Profile carrying world, memory, routing,
// AI, voice, renderer, soundscape, automation-pack, Soul, and
// command-database defaults (WM-SPEC-010-R01).
#pragma once

#include <QJsonArray>
#include <QJsonObject>
#include <QString>
#include <QVector>

namespace wiremudder {

constexpr int PROFILE_SCHEMA_VERSION = 1;

enum class DefaultDomain {
    World,
    Memory,
    Routing,
    Ai,
    Voice,
    Renderer,
    Soundscape,
    AutomationPack,
    Soul,
    CommandDatabase,
};

constexpr DefaultDomain kAllDomains[] = {
        DefaultDomain::World,
        DefaultDomain::Memory,
        DefaultDomain::Routing,
        DefaultDomain::Ai,
        DefaultDomain::Voice,
        DefaultDomain::Renderer,
        DefaultDomain::Soundscape,
        DefaultDomain::AutomationPack,
        DefaultDomain::Soul,
        DefaultDomain::CommandDatabase,
};

constexpr int kDomainCount = 10;

bool domainIsSensitive(DefaultDomain d); // Routing and Ai only.

enum class Actor { User, Automation };

struct ProfileDefaults
{
    QString world;
    QString memory;
    QString routingProfile;
    QString aiProvider;
    QString voice;
    QString renderer;
    QString soundscape;
    QString automationPack;
    QString soulDocument;
    QString commandDatabase;

    QString get(DefaultDomain d) const;
    void set(DefaultDomain d, const QString& value);
};

struct CharacterProfile
{
    QString id;
    QString name;
    int schemaVersion = PROFILE_SCHEMA_VERSION;
    ProfileDefaults defaults;
    qint64 createdAt = 0;
    qint64 updatedAt = 0;

    static CharacterProfile create(const QString& id, const QString& name, QString* err);
    QJsonObject toJson() const;
    static bool fromJson(const QJsonObject& obj, CharacterProfile* out, QString* err);
};

struct SensitiveChangeAudit
{
    qint64 atUnix = 0;
    QString profileId;
    DefaultDomain domain = DefaultDomain::Routing;
    Actor actor = Actor::User;
    QString valueRedacted;
};

class ProfileStoreQt
{
public:
    ProfileStoreQt() = default;

    // Upsert with the same actor rule as the Rust core: Automation
    // cannot create profiles or mutate sensitive defaults (WM-SPEC-006-R08).
    bool upsert(const CharacterProfile& profile, Actor actor, QString* err);
    const CharacterProfile* get(const QString& id) const;
    QVector<const CharacterProfile*> list() const;
    bool remove(const QString& id, QString* err);
    int count() const { return m_profiles.size(); }

    // Local-first persistence: JSON array in a caller-provided directory.
    bool saveToDir(const QString& dir, QString* err) const;
    bool loadFromDir(const QString& dir, QString* err);

    QString exportJson(QString* err) const;
    bool importJson(const QString& json, Actor actor, QString* err);

    const QVector<SensitiveChangeAudit>& sensitiveChangeAudit() const { return m_audit; }

private:
    QVector<CharacterProfile> m_profiles;
    QVector<SensitiveChangeAudit> m_audit;

    const CharacterProfile* find(const QString& id) const;
    CharacterProfile* findMutable(const QString& id);
};

} // namespace wiremudder
