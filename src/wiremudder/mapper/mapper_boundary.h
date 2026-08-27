// WireMudder Mapper Boundary (EP-013 M2)
//
// Namespaced C++ surface for the world graph: rooms, areas, zones, typed
// exits, weighted/timed routing, derived-fact provenance, corrections,
// and a bounded hot cache. The inherited Mudlet mapper stays canonical;
// this boundary provides deterministic, testable invariants for
// WM-FEAT-0165..0168 and WM-SPEC-012-R02/R03/R04/R05/R10.
#pragma once

#include <QHash>
#include <QList>
#include <QSet>
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <optional>

namespace wiremudder::mapper {

// Typed exit kinds (WM-FEAT-0166).
enum class ExitKind { Normal, Hidden, Locked, OneWay, Portal };
// Door status modeled after inherited TRoom::setDoor (WM-SPEC-005-R07).
enum class DoorStatus { None, Open, Closed, Locked };
// Room identity confidence (WM-SPEC-012-R05).
enum class IdentityState { Confirmed, Ambiguous, Corrected };

// Timed exit availability window in minutes of day [0, 1440).
struct TimedWindow {
    quint32 startMinute = 0;
    quint32 endMinute = 0;

    bool contains(quint32 minute) const {
        if (startMinute <= endMinute) {
            return minute >= startMinute && minute < endMinute;
        }
        return minute >= startMinute || minute < endMinute; // overnight wrap
    }
};

// A single typed exit (WM-FEAT-0166, WM-SPEC-005-R07).
struct ExitSpec {
    quint32 to = 0;
    QString command;
    ExitKind kind = ExitKind::Normal;
    quint32 weight = 1;
    DoorStatus door = DoorStatus::None;
    std::optional<TimedWindow> timed;
};

// Room snapshot (WM-SPEC-005-R07).
struct RoomSnapshot {
    quint32 id = 0;
    quint32 area = 0;
    QString name;
    int x = 0;
    int y = 0;
    int z = 0;
    IdentityState identity = IdentityState::Confirmed;
    QList<ExitSpec> exits;
};

// Area grouping (WM-FEAT-0165).
struct AreaSpec {
    quint32 id = 0;
    QString name;
    std::optional<quint32> zone;
    QSet<quint32> roomIds;
};

// Zone clustering (WM-FEAT-0165).
struct ZoneSpec {
    quint32 id = 0;
    QString name;
    QSet<quint32> areaIds;
};

// Route result (WM-FEAT-0167).
struct RouteResult {
    quint32 from = 0;
    quint32 to = 0;
    QList<quint32> nodes;
    QStringList commands;
    quint64 totalWeight = 0;
};

// Derived fact provenance (WM-SPEC-012-R02).
enum class Sensitivity { Public, Private, Secret };

struct DerivedFact {
    quint64 id = 0;
    QString sourceEvent;
    quint64 time = 0;
    QString scope;
    double confidence = 0.0;
    Sensitivity sensitivity = Sensitivity::Public;
    QString modelVersion;
    std::optional<quint64> supersededBy;
    QVariantMap payload;
};

struct Correction {
    quint64 factId = 0;
    quint64 time = 0;
    QVariantMap payload;
    QString note;
};

// Bounded hot current-state cache (WM-SPEC-012-R03).
class HotCacheQt {
public:
    static constexpr int kMaxEntries = 4096;

    void setCurrentRoom(quint32 room) { currentRoom_ = room; }
    std::optional<quint32> currentRoom() const { return currentRoom_; }

    bool set(const QString& key, const QVariant& value) {
        if (!entries_.contains(key) && entries_.size() >= kMaxEntries) {
            return false;
        }
        entries_.insert(key, value);
        return true;
    }
    std::optional<QVariant> get(const QString& key) const {
        if (!entries_.contains(key)) {
            return std::nullopt;
        }
        return entries_.value(key);
    }
    int size() const { return entries_.size(); }

private:
    std::optional<quint32> currentRoom_;
    QHash<QString, QVariant> entries_;
};

// World graph core (WM-FEAT-0165..0168).
class WorldGraphQt {
public:
    static constexpr quint32 kSchemaVersion = 1;
    static constexpr int kMaxRooms = 1000000;
    static constexpr int kMaxExitsPerRoom = 64;
    static constexpr int kMaxEventLog = 8192;

    bool addRoom(const RoomSnapshot& room);
    bool addArea(const AreaSpec& area);
    bool addZone(const ZoneSpec& zone);
    bool assignAreaToZone(quint32 areaId, quint32 zoneId);
    QList<quint32> roomsInZone(quint32 zoneId) const;

    bool addExit(quint32 from, const ExitSpec& exit);
    const RoomSnapshot* room(quint32 id) const;
    int roomCount() const { return rooms_.size(); }

    // Weighted/timed A*-style routing (deterministic Dijkstra).
    // `now` = minute of day; nullopt ignores timed windows. Hidden exits
    // routable only when allowHidden is true.
    std::optional<RouteResult> route(quint32 from, quint32 to,
                                     std::optional<quint32> now,
                                     bool allowHidden) const;

    // Derived facts and corrections (WM-SPEC-012-R02/R10).
    quint64 insertFact(const QString& sourceEvent, quint64 time,
                       const QString& scope, double confidence,
                       Sensitivity sensitivity, const QString& modelVersion,
                       const QVariantMap& payload);
    bool applyCorrection(quint64 factId, quint64 time,
                         const QVariantMap& payload, const QString& note);
    int activeFactCount() const;
    int correctionCount() const { return corrections_.size(); }

    // Hot cache (WM-SPEC-012-R03).
    HotCacheQt& cache() { return cache_; }
    const HotCacheQt& cache() const { return cache_; }

    // Versioned JSON export/import (WM-FEAT-0168, SPEC-021).
    QString exportJson() const;
    bool importJson(const QString& json);

private:
    QHash<quint32, RoomSnapshot> rooms_;
    QHash<quint32, AreaSpec> areas_;
    QHash<quint32, ZoneSpec> zones_;
    QList<DerivedFact> facts_;
    QList<Correction> corrections_;
    HotCacheQt cache_;
};

} // namespace wiremudder::mapper
