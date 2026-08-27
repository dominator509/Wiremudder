// WireMudder character memory profile store (Qt layer).
#include "character_profile_store.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonDocument>

namespace wiremudder {

bool domainIsSensitive(DefaultDomain d) {
    return d == DefaultDomain::Routing || d == DefaultDomain::Ai;
}

QString ProfileDefaults::get(DefaultDomain d) const {
    switch (d) {
        case DefaultDomain::World: return world;
        case DefaultDomain::Memory: return memory;
        case DefaultDomain::Routing: return routingProfile;
        case DefaultDomain::Ai: return aiProvider;
        case DefaultDomain::Voice: return voice;
        case DefaultDomain::Renderer: return renderer;
        case DefaultDomain::Soundscape: return soundscape;
        case DefaultDomain::AutomationPack: return automationPack;
        case DefaultDomain::Soul: return soulDocument;
        case DefaultDomain::CommandDatabase: return commandDatabase;
    }
    return QString();
}

void ProfileDefaults::set(DefaultDomain d, const QString& value) {
    switch (d) {
        case DefaultDomain::World: world = value; break;
        case DefaultDomain::Memory: memory = value; break;
        case DefaultDomain::Routing: routingProfile = value; break;
        case DefaultDomain::Ai: aiProvider = value; break;
        case DefaultDomain::Voice: voice = value; break;
        case DefaultDomain::Renderer: renderer = value; break;
        case DefaultDomain::Soundscape: soundscape = value; break;
        case DefaultDomain::AutomationPack: automationPack = value; break;
        case DefaultDomain::Soul: soulDocument = value; break;
        case DefaultDomain::CommandDatabase: commandDatabase = value; break;
    }
}

CharacterProfile CharacterProfile::create(const QString& id, const QString& name, QString* err) {
    CharacterProfile p;
    if (id.isEmpty() || id.size() > 128) {
        if (err) *err = "invalid id";
        return p;
    }
    if (name.isEmpty() || name.size() > 256) {
        if (err) *err = "invalid name";
        return p;
    }
    p.id = id;
    p.name = name;
    p.schemaVersion = PROFILE_SCHEMA_VERSION;
    p.createdAt = QDateTime::currentSecsSinceEpoch();
    p.updatedAt = p.createdAt;
    if (err) *err = QString();
    return p;
}

QJsonObject CharacterProfile::toJson() const {
    QJsonObject o;
    o.insert("id", id);
    o.insert("name", name);
    o.insert("schema_version", schemaVersion);
    o.insert("created_at", createdAt);
    o.insert("updated_at", updatedAt);
    QJsonObject d;
    d.insert("world", defaults.world);
    d.insert("memory", defaults.memory);
    d.insert("routing_profile", defaults.routingProfile);
    d.insert("ai_provider", defaults.aiProvider);
    d.insert("voice", defaults.voice);
    d.insert("renderer", defaults.renderer);
    d.insert("soundscape", defaults.soundscape);
    d.insert("automation_pack", defaults.automationPack);
    d.insert("soul_document", defaults.soulDocument);
    d.insert("command_database", defaults.commandDatabase);
    o.insert("defaults", d);
    return o;
}

bool CharacterProfile::fromJson(const QJsonObject& obj, CharacterProfile* out, QString* err) {
    CharacterProfile p;
    p.id = obj.value("id").toString();
    p.name = obj.value("name").toString();
    p.schemaVersion = obj.value("schema_version").toInt();
    p.createdAt = obj.value("created_at").toVariant().toLongLong();
    p.updatedAt = obj.value("updated_at").toVariant().toLongLong();
    const QJsonObject d = obj.value("defaults").toObject();
    p.defaults.world = d.value("world").toString();
    p.defaults.memory = d.value("memory").toString();
    p.defaults.routingProfile = d.value("routing_profile").toString();
    p.defaults.aiProvider = d.value("ai_provider").toString();
    p.defaults.voice = d.value("voice").toString();
    p.defaults.renderer = d.value("renderer").toString();
    p.defaults.soundscape = d.value("soundscape").toString();
    p.defaults.automationPack = d.value("automation_pack").toString();
    p.defaults.soulDocument = d.value("soul_document").toString();
    p.defaults.commandDatabase = d.value("command_database").toString();
    if (p.id.isEmpty() || p.name.isEmpty()) {
        if (err) *err = "malformed profile";
        return false;
    }
    if (p.schemaVersion != PROFILE_SCHEMA_VERSION) {
        if (err) *err = QString("schema version mismatch: %1").arg(p.schemaVersion);
        return false;
    }
    *out = p;
    if (err) *err = QString();
    return true;
}

const CharacterProfile* ProfileStoreQt::find(const QString& id) const {
    for (const auto& p : m_profiles) {
        if (p.id == id) return &p;
    }
    return nullptr;
}

CharacterProfile* ProfileStoreQt::findMutable(const QString& id) {
    for (auto& p : m_profiles) {
        if (p.id == id) return &p;
    }
    return nullptr;
}

bool ProfileStoreQt::upsert(const CharacterProfile& profile, Actor actor, QString* err) {
    CharacterProfile* existing = findMutable(profile.id);
    if (existing) {
        for (DefaultDomain d : kAllDomains) {
            const QString oldV = existing->defaults.get(d);
            const QString newV = profile.defaults.get(d);
            if (oldV != newV && domainIsSensitive(d)) {
                if (actor != Actor::User) {
                    if (err) *err = "sensitive default change denied for non-user actor";
                    return false;
                }
                SensitiveChangeAudit a;
                a.atUnix = QDateTime::currentSecsSinceEpoch();
                a.profileId = profile.id;
                a.domain = d;
                a.actor = actor;
                a.valueRedacted = newV.isEmpty() ? QString() : QStringLiteral("redacted:");
                m_audit.append(a);
            }
        }
    } else if (actor != Actor::User) {
        if (err) *err = "profile creation denied for non-user actor";
        return false;
    }
    CharacterProfile p = profile;
    p.updatedAt = QDateTime::currentSecsSinceEpoch();
    if (existing) {
        *existing = p;
    } else {
        m_profiles.append(p);
    }
    if (err) *err = QString();
    return true;
}

const CharacterProfile* ProfileStoreQt::get(const QString& id) const {
    return find(id);
}

QVector<const CharacterProfile*> ProfileStoreQt::list() const {
    QVector<const CharacterProfile*> out;
    for (const auto& p : m_profiles) out.append(&p);
    std::sort(out.begin(), out.end(),
              [](const CharacterProfile* a, const CharacterProfile* b) { return a->name < b->name; });
    return out;
}

bool ProfileStoreQt::remove(const QString& id, QString* err) {
    for (int i = 0; i < m_profiles.size(); ++i) {
        if (m_profiles[i].id == id) {
            m_profiles.removeAt(i);
            if (err) *err = QString();
            return true;
        }
    }
    if (err) *err = "not found";
    return false;
}

QString ProfileStoreQt::exportJson(QString* err) const {
    QJsonArray arr;
    for (const auto& p : m_profiles) arr.append(p.toJson());
    const QJsonDocument doc(arr);
    if (err) *err = QString();
    return QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
}

bool ProfileStoreQt::importJson(const QString& json, Actor actor, QString* err) {
    if (actor != Actor::User) {
        if (err) *err = "import denied for non-user actor";
        return false;
    }
    QJsonParseError pe;
    const QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8(), &pe);
    if (pe.error != QJsonParseError::NoError || !doc.isArray()) {
        if (err) *err = "malformed json";
        return false;
    }
    for (const auto v : doc.array()) {
        CharacterProfile p;
        QString e;
        if (!CharacterProfile::fromJson(v.toObject(), &p, &e)) {
            if (err) *err = e;
            return false;
        }
        if (find(p.id)) {
            if (err) *err = "duplicate id";
            return false;
        }
        m_profiles.append(p);
    }
    if (err) *err = QString();
    return true;
}

bool ProfileStoreQt::saveToDir(const QString& dir, QString* err) const {
    QDir d(dir);
    if (!d.exists() && !d.mkpath(".")) {
        if (err) *err = "cannot create dir";
        return false;
    }
    QFile f(d.filePath("profiles.json"));
    if (!f.open(QIODevice::WriteOnly)) {
        if (err) *err = "cannot write profiles.json";
        return false;
    }
    QString e;
    const QString json = exportJson(&e);
    f.write(json.toUtf8());
    f.close();
    if (err) *err = QString();
    return true;
}

bool ProfileStoreQt::loadFromDir(const QString& dir, QString* err) {
    QFile f(QDir(dir).filePath("profiles.json"));
    if (!f.exists()) {
        if (err) *err = QString();
        return true;  // empty store on first run
    }
    if (!f.open(QIODevice::ReadOnly)) {
        if (err) *err = "cannot read profiles.json";
        return false;
    }
    const QString json = QString::fromUtf8(f.readAll());
    f.close();
    return importJson(json, Actor::User, err);
}

}  // namespace wiremudder
