// WireMudder EP-013 M3 parity oracle (C++ side).
// Prints the same deterministic matrix as the Rust world_matrix example;
// the integration test diffs the two outputs.
#include "src/wiremudder/mapper/mapper_boundary.h"

#include <QCoreApplication>
#include <QString>
#include <cstdio>

using namespace wiremudder::mapper;

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

static QString boolStr(bool b) { return b ? QStringLiteral("true") : QStringLiteral("false"); }

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);

    // 1. Line graph.
    WorldGraphQt g;
    for (quint32 i = 1; i <= 5; ++i) {
        g.addRoom(room(i, 1));
    }
    for (quint32 i = 1; i < 5; ++i) {
        g.addExit(i, exitSpec(i + 1, QStringLiteral("n%1").arg(i), ExitKind::Normal));
    }
    auto r = g.route(1, 5, std::nullopt, false);
    std::printf("route:1->5:%llu:%s\n",
                static_cast<unsigned long long>(r->totalWeight),
                r->commands.join(",").toUtf8().constData());

    // 2. One-way.
    WorldGraphQt ow;
    ow.addRoom(room(1, 1));
    ow.addRoom(room(2, 1));
    ow.addExit(1, exitSpec(2, QStringLiteral("east"), ExitKind::OneWay));
    std::printf("one-way:1->2:%s\n", boolStr(ow.route(1, 2, std::nullopt, false).has_value()).toUtf8().constData());
    std::printf("one-way:2->1:%s\n", boolStr(!ow.route(2, 1, std::nullopt, false).has_value()).toUtf8().constData());

    // 3. Locked.
    WorldGraphQt lk;
    lk.addRoom(room(1, 1));
    lk.addRoom(room(2, 1));
    lk.addExit(1, exitSpec(2, QStringLiteral("east"), ExitKind::Locked));
    std::printf("locked:1->2:%s\n", boolStr(!lk.route(1, 2, std::nullopt, false).has_value()).toUtf8().constData());

    // 4. Hidden.
    WorldGraphQt hd;
    hd.addRoom(room(1, 1));
    hd.addRoom(room(2, 1));
    hd.addExit(1, exitSpec(2, QStringLiteral("secret"), ExitKind::Hidden));
    std::printf("hidden:1->2:%s\n", boolStr(!hd.route(1, 2, std::nullopt, false).has_value()).toUtf8().constData());
    std::printf("hidden-optin:1->2:%s\n", boolStr(hd.route(1, 2, std::nullopt, true).has_value()).toUtf8().constData());

    // 5. Timed window.
    WorldGraphQt tm;
    tm.addRoom(room(1, 1));
    tm.addRoom(room(2, 1));
    TimedWindow w;
    w.startMinute = 600;
    w.endMinute = 660;
    tm.addExit(1, exitSpec(2, QStringLiteral("gate"), ExitKind::Normal, 1, DoorStatus::None, w));
    std::printf("timed-open:1->2:%s\n", boolStr(tm.route(1, 2, quint32(610), false).has_value()).toUtf8().constData());
    std::printf("timed-closed:1->2:%s\n", boolStr(!tm.route(1, 2, quint32(100), false).has_value()).toUtf8().constData());
    std::printf("timed-noctx:1->2:%s\n", boolStr(!tm.route(1, 2, std::nullopt, false).has_value()).toUtf8().constData());

    // 6. Weighted.
    WorldGraphQt wg;
    wg.addRoom(room(1, 1));
    wg.addRoom(room(2, 1));
    wg.addRoom(room(3, 1));
    wg.addExit(1, exitSpec(3, QStringLiteral("east"), ExitKind::Normal, 10));
    wg.addExit(1, exitSpec(2, QStringLiteral("ne"), ExitKind::Normal, 2));
    wg.addExit(2, exitSpec(3, QStringLiteral("se"), ExitKind::Normal, 2));
    auto wr = wg.route(1, 3, std::nullopt, false);
    QStringList nodes;
    for (quint32 n : wr->nodes) {
        nodes << QString::number(n);
    }
    std::printf("weighted:1->3:%llu:%s\n",
                static_cast<unsigned long long>(wr->totalWeight),
                nodes.join(",").toUtf8().constData());

    // 7. Zones.
    WorldGraphQt zg;
    AreaSpec a1;
    a1.id = 1;
    a1.name = QStringLiteral("A");
    a1.roomIds = {1, 2};
    AreaSpec a2;
    a2.id = 2;
    a2.name = QStringLiteral("B");
    a2.roomIds = {3};
    zg.addArea(a1);
    zg.addArea(a2);
    ZoneSpec z;
    z.id = 1;
    z.name = QStringLiteral("Z");
    zg.addZone(z);
    zg.assignAreaToZone(1, 1);
    zg.assignAreaToZone(2, 1);
    QStringList zrooms;
    for (quint32 n : zg.roomsInZone(1)) {
        zrooms << QString::number(n);
    }
    std::printf("zone:1:%s\n", zrooms.join(",").toUtf8().constData());

    // 8. Round-trip.
    QString json = g.exportJson();
    WorldGraphQt g2;
    g2.importJson(json);
    auto r2 = g2.route(1, 5, std::nullopt, false);
    bool roundtrip = r2.has_value() && r2->totalWeight == 4 && r2->nodes == QList<quint32>({1, 2, 3, 4, 5});
    std::printf("roundtrip:%s\n", boolStr(roundtrip).toUtf8().constData());

    // 9. Facts.
    quint64 fid = g.insertFact(QStringLiteral("room-enter#42"), 1000,
                               QStringLiteral("profile:dom"), 0.9,
                               Sensitivity::Private, QStringLiteral("rule-v1"),
                               QVariantMap{{QStringLiteral("room"), 1}});
    g.applyCorrection(fid, 2000, QVariantMap{{QStringLiteral("room"), 7}},
                      QStringLiteral("user said room 7"));
    std::printf("facts:%llu:%d:%d\n", static_cast<unsigned long long>(fid),
                g.activeFactCount(), g.correctionCount());

    return 0;
}
