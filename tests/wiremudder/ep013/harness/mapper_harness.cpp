// WireMudder EP-013 M2 mapper boundary harness.
// Deterministic unit checks over the C++ WorldGraphQt boundary.
#include "src/wiremudder/mapper/mapper_boundary.h"

#include <QCoreApplication>
#include <QString>
#include <cstdio>

using namespace wiremudder::mapper;

static int failures = 0;

#define CHECK(cond)                                                     \
    do {                                                                \
        if (!(cond)) {                                                  \
            std::fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond); \
            ++failures;                                                 \
        }                                                               \
    } while (0)

static RoomSnapshot room(quint32 id, quint32 area) {
    RoomSnapshot r;
    r.id = id;
    r.area = area;
    r.name = QStringLiteral("room-%1").arg(id);
    r.x = static_cast<int>(id);
    r.y = 0;
    r.z = 0;
    return r;
}

static ExitSpec exitSpec(quint32 to, const QString& cmd, ExitKind kind,
                         quint32 weight = 1, DoorStatus door = DoorStatus::None,
                         std::optional<TimedWindow> timed = std::nullopt) {
    ExitSpec e;
    e.to = to;
    e.command = cmd;
    e.kind = kind;
    e.weight = weight;
    e.door = door;
    e.timed = timed;
    return e;
}

static void test_shortest_path() {
    WorldGraphQt g;
    for (quint32 i = 1; i <= 5; ++i) {
        CHECK(g.addRoom(room(i, 1)));
    }
    for (quint32 i = 1; i < 5; ++i) {
        CHECK(g.addExit(i, exitSpec(i + 1, QStringLiteral("n%1").arg(i),
                                    ExitKind::Normal)));
    }
    auto r = g.route(1, 5, std::nullopt, false);
    CHECK(r.has_value());
    CHECK(r->nodes == QList<quint32>({1, 2, 3, 4, 5}));
    CHECK(r->commands == QStringList({QStringLiteral("n1"), QStringLiteral("n2"),
                                      QStringLiteral("n3"), QStringLiteral("n4")}));
    CHECK(r->totalWeight == 4);
}

static void test_one_way() {
    WorldGraphQt g;
    CHECK(g.addRoom(room(1, 1)));
    CHECK(g.addRoom(room(2, 1)));
    CHECK(g.addExit(1, exitSpec(2, QStringLiteral("east"), ExitKind::OneWay)));
    CHECK(g.route(1, 2, std::nullopt, false).has_value());
    CHECK(!g.route(2, 1, std::nullopt, false).has_value());
}

static void test_locked_hidden_timed() {
    WorldGraphQt g;
    CHECK(g.addRoom(room(1, 1)));
    CHECK(g.addRoom(room(2, 1)));
    CHECK(g.addExit(1, exitSpec(2, QStringLiteral("east"), ExitKind::Locked)));
    CHECK(!g.route(1, 2, std::nullopt, false).has_value());

    WorldGraphQt h;
    CHECK(h.addRoom(room(1, 1)));
    CHECK(h.addRoom(room(2, 1)));
    CHECK(h.addExit(1, exitSpec(2, QStringLiteral("secret"), ExitKind::Hidden)));
    CHECK(!h.route(1, 2, std::nullopt, false).has_value());
    CHECK(h.route(1, 2, std::nullopt, true).has_value());

    WorldGraphQt t;
    CHECK(t.addRoom(room(1, 1)));
    CHECK(t.addRoom(room(2, 1)));
    TimedWindow w;
    w.startMinute = 600;
    w.endMinute = 660;
    CHECK(t.addExit(1, exitSpec(2, QStringLiteral("gate"), ExitKind::Normal,
                                1, DoorStatus::None, w)));
    CHECK(t.route(1, 2, quint32(610), false).has_value());
    CHECK(!t.route(1, 2, quint32(100), false).has_value());
    CHECK(!t.route(1, 2, std::nullopt, false).has_value());
}

static void test_weighted() {
    WorldGraphQt g;
    CHECK(g.addRoom(room(1, 1)));
    CHECK(g.addRoom(room(2, 1)));
    CHECK(g.addRoom(room(3, 1)));
    CHECK(g.addExit(1, exitSpec(3, QStringLiteral("east"), ExitKind::Normal, 10)));
    CHECK(g.addExit(1, exitSpec(2, QStringLiteral("ne"), ExitKind::Normal, 2)));
    CHECK(g.addExit(2, exitSpec(3, QStringLiteral("se"), ExitKind::Normal, 2)));
    auto r = g.route(1, 3, std::nullopt, false);
    CHECK(r.has_value());
    CHECK(r->nodes == QList<quint32>({1, 2, 3}));
    CHECK(r->totalWeight == 4);
}

static void test_zones() {
    WorldGraphQt g;
    AreaSpec a1;
    a1.id = 1;
    a1.name = QStringLiteral("A");
    a1.roomIds = {1, 2};
    AreaSpec a2;
    a2.id = 2;
    a2.name = QStringLiteral("B");
    a2.roomIds = {3};
    CHECK(g.addArea(a1));
    CHECK(g.addArea(a2));
    ZoneSpec z;
    z.id = 1;
    z.name = QStringLiteral("Z");
    CHECK(g.addZone(z));
    CHECK(g.assignAreaToZone(1, 1));
    CHECK(g.assignAreaToZone(2, 1));
    CHECK(g.roomsInZone(1) == QList<quint32>({1, 2, 3}));
    // unknown zone rejected
    CHECK(!g.assignAreaToZone(1, 99));
}

static void test_duplicate_exit_and_bounds() {
    WorldGraphQt g;
    CHECK(g.addRoom(room(1, 1)));
    CHECK(g.addRoom(room(2, 1)));
    CHECK(g.addExit(1, exitSpec(2, QStringLiteral("east"), ExitKind::Normal)));
    CHECK(!g.addExit(1, exitSpec(2, QStringLiteral("east"), ExitKind::OneWay)));
    for (int i = 0; i < WorldGraphQt::kMaxExitsPerRoom - 1; ++i) {
        CHECK(g.addExit(1, exitSpec(2, QStringLiteral("cmd%1").arg(i),
                                    ExitKind::Normal)));
    }
    CHECK(!g.addExit(1, exitSpec(2, QStringLiteral("overflow"),
                                 ExitKind::Normal)));
    // invalid timed window rejected
    WorldGraphQt t;
    CHECK(t.addRoom(room(1, 1)));
    CHECK(t.addRoom(room(2, 1)));
    TimedWindow bad;
    bad.startMinute = 1500;
    bad.endMinute = 1600;
    CHECK(!t.addExit(1, exitSpec(2, QStringLiteral("gate"), ExitKind::Normal,
                                 1, DoorStatus::None, bad)));
}

static void test_facts_and_corrections() {
    WorldGraphQt g;
    quint64 id = g.insertFact(QStringLiteral("room-enter#42"), 1000,
                              QStringLiteral("profile:dom"), 0.9,
                              Sensitivity::Private, QStringLiteral("rule-v1"),
                              QVariantMap{{QStringLiteral("room"), 1}});
    CHECK(id == 1);
    CHECK(g.activeFactCount() == 1);
    CHECK(g.applyCorrection(id, 2000,
                            QVariantMap{{QStringLiteral("room"), 7}},
                            QStringLiteral("user said room 7")));
    CHECK(g.activeFactCount() == 0);
    CHECK(g.correctionCount() == 1);
    CHECK(!g.applyCorrection(999, 2000, QVariantMap{}, QStringLiteral("x")));
}

static void test_hot_cache() {
    WorldGraphQt g;
    g.cache().setCurrentRoom(5);
    CHECK(g.cache().currentRoom().has_value() && g.cache().currentRoom() == 5);
    for (int i = 0; i < HotCacheQt::kMaxEntries; ++i) {
        CHECK(g.cache().set(QStringLiteral("k%1").arg(i), i));
    }
    CHECK(!g.cache().set(QStringLiteral("overflow"), 1));
}

static void test_export_import() {
    WorldGraphQt g;
    for (quint32 i = 1; i <= 5; ++i) {
        CHECK(g.addRoom(room(i, 1)));
    }
    for (quint32 i = 1; i < 5; ++i) {
        CHECK(g.addExit(i, exitSpec(i + 1, QStringLiteral("n%1").arg(i),
                                    ExitKind::Normal)));
    }
    AreaSpec a1;
    a1.id = 1;
    a1.name = QStringLiteral("A");
    a1.roomIds = {1, 2, 3, 4, 5};
    CHECK(g.addArea(a1));
    QString json = g.exportJson();
    WorldGraphQt g2;
    CHECK(g2.importJson(json));
    CHECK(g2.roomCount() == g.roomCount());
    auto r = g2.route(1, 5, std::nullopt, false);
    CHECK(r.has_value() && r->nodes == QList<quint32>({1, 2, 3, 4, 5}));
    // wrong version rejected
    QString bad = json;
    CHECK(!g2.importJson(QStringLiteral("{\"schema_version\": 999, \"rooms\": []}")));
    CHECK(!g2.importJson(QStringLiteral("not json")));
}

static void test_ambiguous_identity() {
    WorldGraphQt g;
    RoomSnapshot a = room(1, 1);
    a.name = QStringLiteral("Market Square");
    a.identity = IdentityState::Ambiguous;
    RoomSnapshot b = room(2, 1);
    b.name = QStringLiteral("Market Square");
    b.identity = IdentityState::Ambiguous;
    CHECK(g.addRoom(a));
    CHECK(g.addRoom(b));
    CHECK(g.roomCount() == 2); // no silent merge
    CHECK(g.room(1)->identity == IdentityState::Ambiguous);
    CHECK(g.room(2)->identity == IdentityState::Ambiguous);
}

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    test_shortest_path();
    test_one_way();
    test_locked_hidden_timed();
    test_weighted();
    test_zones();
    test_duplicate_exit_and_bounds();
    test_facts_and_corrections();
    test_hot_cache();
    test_export_import();
    test_ambiguous_identity();
    if (failures != 0) {
        std::fprintf(stderr, "mapper boundary: FAIL (%d)\n", failures);
        return 1;
    }
    std::printf("mapper boundary unit: ok\n");
    return 0;
}
