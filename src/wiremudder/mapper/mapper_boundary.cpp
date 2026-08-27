// WireMudder Mapper Boundary implementation (EP-013 M2).
#include "src/wiremudder/mapper/mapper_boundary.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <algorithm>

namespace wiremudder::mapper {

namespace {

QString exitKindName(ExitKind kind) {
    switch (kind) {
        case ExitKind::Normal: return QStringLiteral("normal");
        case ExitKind::Hidden: return QStringLiteral("hidden");
        case ExitKind::Locked: return QStringLiteral("locked");
        case ExitKind::OneWay: return QStringLiteral("one-way");
        case ExitKind::Portal: return QStringLiteral("portal");
    }
    return QStringLiteral("normal");
}

QString doorStatusName(DoorStatus door) {
    switch (door) {
        case DoorStatus::None: return QStringLiteral("none");
        case DoorStatus::Open: return QStringLiteral("open");
        case DoorStatus::Closed: return QStringLiteral("closed");
        case DoorStatus::Locked: return QStringLiteral("locked");
    }
    return QStringLiteral("none");
}

// QJsonValue construction from quint32 is ambiguous (int vs double);
// force the signed 64-bit path used by the schemas.
QJsonValue jv(quint32 v) { return QJsonValue(static_cast<qint64>(v)); }

} // namespace

bool WorldGraphQt::addRoom(const RoomSnapshot& room) {
    if (rooms_.size() >= kMaxRooms) {
        return false;
    }
    if (room.exits.size() > kMaxExitsPerRoom) {
        return false;
    }
    rooms_.insert(room.id, room);
    return true;
}

bool WorldGraphQt::addArea(const AreaSpec& area) {
    if (areas_.contains(area.id)) {
        return false;
    }
    areas_.insert(area.id, area);
    return true;
}

bool WorldGraphQt::addZone(const ZoneSpec& zone) {
    if (zones_.contains(zone.id)) {
        return false;
    }
    zones_.insert(zone.id, zone);
    return true;
}

bool WorldGraphQt::assignAreaToZone(quint32 areaId, quint32 zoneId) {
    auto areaIt = areas_.find(areaId);
    auto zoneIt = zones_.find(zoneId);
    if (areaIt == areas_.end() || zoneIt == zones_.end()) {
        return false;
    }
    areaIt->zone = zoneId;
    zoneIt->areaIds.insert(areaId);
    return true;
}

QList<quint32> WorldGraphQt::roomsInZone(quint32 zoneId) const {
    QSet<quint32> out;
    auto zoneIt = zones_.find(zoneId);
    if (zoneIt != zones_.end()) {
        for (quint32 areaId : zoneIt->areaIds) {
            auto areaIt = areas_.find(areaId);
            if (areaIt != areas_.end()) {
                out += areaIt->roomIds;
            }
        }
    }
    QList<quint32> list = out.values();
    std::sort(list.begin(), list.end());
    return list;
}

bool WorldGraphQt::addExit(quint32 from, const ExitSpec& exit) {
    if (!rooms_.contains(from) || !rooms_.contains(exit.to)) {
        return false;
    }
    if (exit.timed.has_value()) {
        if (exit.timed->startMinute >= 1440 || exit.timed->endMinute >= 1440) {
            return false;
        }
    }
    auto it = rooms_.find(from);
    if (it->exits.size() >= kMaxExitsPerRoom) {
        return false;
    }
    for (const ExitSpec& e : it->exits) {
        if (e.command == exit.command) {
            return false; // duplicate exit command
        }
    }
    it->exits.append(exit);
    return true;
}

const RoomSnapshot* WorldGraphQt::room(quint32 id) const {
    auto it = rooms_.find(id);
    return it == rooms_.end() ? nullptr : &it.value();
}

std::optional<RouteResult> WorldGraphQt::route(quint32 from, quint32 to,
                                               std::optional<quint32> now,
                                               bool allowHidden) const {
    if (!rooms_.contains(from) || !rooms_.contains(to)) {
        return std::nullopt;
    }
    if (from == to) {
        RouteResult r;
        r.from = from;
        r.to = to;
        r.nodes.append(from);
        return r;
    }

    QHash<quint32, quint64> dist;
    QHash<quint32, QPair<quint32, QString>> prev;
    QSet<quint32> visited;
    dist.insert(from, 0);

    for (;;) {
        // Deterministic Dijkstra: pick unvisited node with smallest dist.
        quint32 cur = 0;
        bool found = false;
        quint64 best = 0;
        QList<quint32> keys = dist.keys();
        std::sort(keys.begin(), keys.end());
        for (quint32 k : keys) {
            if (visited.contains(k)) {
                continue;
            }
            if (!found || dist.value(k) < best) {
                found = true;
                cur = k;
                best = dist.value(k);
            }
        }
        if (!found || cur == to) {
            break;
        }
        visited.insert(cur);
        auto it = rooms_.find(cur);
        if (it == rooms_.end()) {
            continue;
        }
        quint64 dCur = dist.value(cur);
        for (const ExitSpec& exit : it->exits) {
            if (exit.kind == ExitKind::Locked) {
                continue;
            }
            if (exit.kind == ExitKind::Hidden && !allowHidden) {
                continue;
            }
            if (exit.door == DoorStatus::Locked) {
                continue;
            }
            if (exit.timed.has_value()) {
                if (!now.has_value()) {
                    continue;
                }
                if (!exit.timed->contains(now.value())) {
                    continue;
                }
            }
            quint64 nd = dCur + qMax<quint32>(exit.weight, 1);
            if (!dist.contains(exit.to) || nd < dist.value(exit.to)) {
                dist.insert(exit.to, nd);
                prev.insert(exit.to, qMakePair(cur, exit.command));
            }
        }
    }

    if (!dist.contains(to)) {
        return std::nullopt;
    }
    RouteResult r;
    r.from = from;
    r.to = to;
    quint32 cur = to;
    while (cur != from) {
        if (!prev.contains(cur)) {
            return std::nullopt;
        }
        auto p = prev.value(cur);
        r.nodes.prepend(cur);
        r.commands.prepend(p.second);
        cur = p.first;
    }
    r.nodes.prepend(from);
    r.totalWeight = dist.value(to);
    return r;
}

quint64 WorldGraphQt::insertFact(const QString& sourceEvent, quint64 time,
                                 const QString& scope, double confidence,
                                 Sensitivity sensitivity,
                                 const QString& modelVersion,
                                 const QVariantMap& payload) {
    DerivedFact f;
    f.id = facts_.size() + 1;
    f.sourceEvent = sourceEvent;
    f.time = time;
    f.scope = scope;
    f.confidence = qBound(0.0, confidence, 1.0);
    f.sensitivity = sensitivity;
    f.modelVersion = modelVersion;
    f.payload = payload;
    facts_.append(f);
    return f.id;
}

bool WorldGraphQt::applyCorrection(quint64 factId, quint64 time,
                                   const QVariantMap& payload,
                                   const QString& note) {
    bool found = false;
    for (DerivedFact& f : facts_) {
        if (f.id == factId) {
            f.supersededBy = facts_.size() + 1;
            f.payload = payload;
            found = true;
        }
    }
    if (!found) {
        return false;
    }
    Correction c;
    c.factId = factId;
    c.time = time;
    c.payload = payload;
    c.note = note;
    corrections_.append(c);
    return true;
}

int WorldGraphQt::activeFactCount() const {
    int n = 0;
    for (const DerivedFact& f : facts_) {
        if (!f.supersededBy.has_value()) {
            ++n;
        }
    }
    return n;
}

QString WorldGraphQt::exportJson() const {
    QJsonObject root;
    root.insert(QStringLiteral("schema_version"),
                QJsonValue::fromVariant(kSchemaVersion));

    QJsonArray roomArr;
    QList<quint32> roomIds = rooms_.keys();
    std::sort(roomIds.begin(), roomIds.end());
    for (quint32 id : roomIds) {
        const RoomSnapshot& r = rooms_.value(id);
        QJsonObject o;
        o.insert(QStringLiteral("id"), jv(id));
        o.insert(QStringLiteral("area"), jv(r.area));
        o.insert(QStringLiteral("name"), r.name);
        o.insert(QStringLiteral("x"), jv(r.x));
        o.insert(QStringLiteral("y"), jv(r.y));
        o.insert(QStringLiteral("z"), jv(r.z));
        o.insert(QStringLiteral("identity"),
                 r.identity == IdentityState::Confirmed
                     ? QStringLiteral("confirmed")
                     : (r.identity == IdentityState::Ambiguous
                            ? QStringLiteral("ambiguous")
                            : QStringLiteral("corrected")));
        QJsonArray exitArr;
        for (const ExitSpec& e : r.exits) {
            QJsonObject x;
            x.insert(QStringLiteral("to"), jv(e.to));
            x.insert(QStringLiteral("command"), e.command);
            x.insert(QStringLiteral("kind"), exitKindName(e.kind));
            x.insert(QStringLiteral("weight"), jv(e.weight));
            x.insert(QStringLiteral("door"), doorStatusName(e.door));
            if (e.timed.has_value()) {
                QJsonObject t;
                t.insert(QStringLiteral("start_minute"),
                         jv(e.timed->startMinute));
                t.insert(QStringLiteral("end_minute"), jv(e.timed->endMinute));
                x.insert(QStringLiteral("timed"), t);
            }
            exitArr.append(x);
        }
        o.insert(QStringLiteral("exits"), exitArr);
        roomArr.append(o);
    }
    root.insert(QStringLiteral("rooms"), roomArr);

    QJsonArray areaArr;
    QList<quint32> areaIds = areas_.keys();
    std::sort(areaIds.begin(), areaIds.end());
    for (quint32 id : areaIds) {
        const AreaSpec& a = areas_.value(id);
        QJsonObject o;
        o.insert(QStringLiteral("id"), jv(id));
        o.insert(QStringLiteral("name"), a.name);
        if (a.zone.has_value()) {
            o.insert(QStringLiteral("zone"), jv(a.zone.value()));
        }
        QJsonArray roomList;
        QList<quint32> rids = a.roomIds.values();
        std::sort(rids.begin(), rids.end());
        for (quint32 rid : rids) {
            roomList.append(jv(rid));
        }
        o.insert(QStringLiteral("rooms"), roomList);
        areaArr.append(o);
    }
    root.insert(QStringLiteral("areas"), areaArr);

    QJsonArray zoneArr;
    QList<quint32> zoneIds = zones_.keys();
    std::sort(zoneIds.begin(), zoneIds.end());
    for (quint32 id : zoneIds) {
        const ZoneSpec& z = zones_.value(id);
        QJsonObject o;
        o.insert(QStringLiteral("id"), jv(id));
        o.insert(QStringLiteral("name"), z.name);
        QJsonArray alist;
        QList<quint32> aids = z.areaIds.values();
        std::sort(aids.begin(), aids.end());
        for (quint32 aid : aids) {
            alist.append(jv(aid));
        }
        o.insert(QStringLiteral("areas"), alist);
        zoneArr.append(o);
    }
    root.insert(QStringLiteral("zones"), zoneArr);

    return QString::fromUtf8(QJsonDocument(root).toJson(QJsonDocument::Compact));
}

bool WorldGraphQt::importJson(const QString& json) {
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) {
        return false;
    }
    QJsonObject root = doc.object();
    if (!root.contains(QStringLiteral("schema_version"))) {
        return false;
    }
    if (root.value(QStringLiteral("schema_version")).toInt() !=
        static_cast<int>(kSchemaVersion)) {
        return false;
    }
    WorldGraphQt fresh;
    for (const QJsonValue& v : root.value(QStringLiteral("rooms")).toArray()) {
        QJsonObject o = v.toObject();
        RoomSnapshot r;
        r.id = o.value(QStringLiteral("id")).toInt();
        r.area = o.value(QStringLiteral("area")).toInt();
        r.name = o.value(QStringLiteral("name")).toString();
        r.x = o.value(QStringLiteral("x")).toInt();
        r.y = o.value(QStringLiteral("y")).toInt();
        r.z = o.value(QStringLiteral("z")).toInt();
        QString idstate = o.value(QStringLiteral("identity")).toString();
        r.identity = idstate == QStringLiteral("ambiguous")
                         ? IdentityState::Ambiguous
                         : (idstate == QStringLiteral("corrected")
                                ? IdentityState::Corrected
                                : IdentityState::Confirmed);
        for (const QJsonValue& xv : o.value(QStringLiteral("exits")).toArray()) {
            QJsonObject x = xv.toObject();
            ExitSpec e;
            e.to = x.value(QStringLiteral("to")).toInt();
            e.command = x.value(QStringLiteral("command")).toString();
            QString kind = x.value(QStringLiteral("kind")).toString();
            e.kind = kind == QStringLiteral("hidden")   ? ExitKind::Hidden
                     : kind == QStringLiteral("locked") ? ExitKind::Locked
                     : kind == QStringLiteral("one-way")
                         ? ExitKind::OneWay
                     : kind == QStringLiteral("portal") ? ExitKind::Portal
                                                        : ExitKind::Normal;
            e.weight = x.value(QStringLiteral("weight")).toInt();
            QString door = x.value(QStringLiteral("door")).toString();
            e.door = door == QStringLiteral("open")     ? DoorStatus::Open
                     : door == QStringLiteral("closed") ? DoorStatus::Closed
                     : door == QStringLiteral("locked") ? DoorStatus::Locked
                                                        : DoorStatus::None;
            if (x.contains(QStringLiteral("timed"))) {
                QJsonObject t = x.value(QStringLiteral("timed")).toObject();
                TimedWindow w;
                w.startMinute = t.value(QStringLiteral("start_minute")).toInt();
                w.endMinute = t.value(QStringLiteral("end_minute")).toInt();
                e.timed = w;
            }
            r.exits.append(e);
        }
        if (!fresh.addRoom(r)) {
            return false;
        }
    }
    for (const QJsonValue& v : root.value(QStringLiteral("areas")).toArray()) {
        QJsonObject o = v.toObject();
        AreaSpec a;
        a.id = o.value(QStringLiteral("id")).toInt();
        a.name = o.value(QStringLiteral("name")).toString();
        if (o.contains(QStringLiteral("zone"))) {
            a.zone = o.value(QStringLiteral("zone")).toInt();
        }
        for (const QJsonValue& rv : o.value(QStringLiteral("rooms")).toArray()) {
            a.roomIds.insert(rv.toInt());
        }
        if (!fresh.addArea(a)) {
            return false;
        }
    }
    for (const QJsonValue& v : root.value(QStringLiteral("zones")).toArray()) {
        QJsonObject o = v.toObject();
        ZoneSpec z;
        z.id = o.value(QStringLiteral("id")).toInt();
        z.name = o.value(QStringLiteral("name")).toString();
        for (const QJsonValue& av : o.value(QStringLiteral("areas")).toArray()) {
            z.areaIds.insert(av.toInt());
        }
        if (!fresh.addZone(z)) {
            return false;
        }
    }
    *this = fresh;
    return true;
}

} // namespace wiremudder::mapper
