// WireMudder Workspace Boundary (EP-012 M2) - implementation.
#include "src/wiremudder/ui/workspace_boundary.h"

namespace wiremudder::ui {

void StatusGaugeQt::set(const models::StatusGauge& g)
{
    for (int i = 0; i < gauges_.size(); ++i) {
        if (gauges_.at(i).id == g.id) {
            gauges_[i] = g;
            return;
        }
    }
    gauges_.append(g);
}

bool StatusGaugeQt::has(const QString& id) const
{
    for (const models::StatusGauge& g : gauges_) {
        if (g.id == id)
            return true;
    }
    return false;
}

QString StatusGaugeQt::value(const QString& id) const
{
    for (const models::StatusGauge& g : gauges_) {
        if (g.id == id)
            return g.value;
    }
    return QString();
}

QStringList StatusGaugeQt::ids() const
{
    QStringList out;
    for (const models::StatusGauge& g : gauges_)
        out << g.id;
    return out;
}

QJsonArray StatusGaugeQt::toJson() const
{
    QJsonArray arr;
    for (const models::StatusGauge& g : gauges_) {
        QJsonObject o;
        o["id"] = g.id;
        o["label"] = g.label;
        o["value"] = g.value;
        o["min"] = g.min;
        o["max"] = g.max;
        arr.append(o);
    }
    return arr;
}

void StatusGaugeQt::fromJson(const QJsonArray& arr)
{
    gauges_.clear();
    for (const auto& v : arr) {
        if (!v.isObject())
            continue;
        const QJsonObject o = v.toObject();
        models::StatusGauge g;
        g.id = o.value("id").toString();
        if (g.id.isEmpty())
            continue;
        g.label = o.value("label").toString();
        g.value = o.value("value").toString();
        g.min = o.value("min").toDouble();
        g.max = o.value("max").toDouble();
        gauges_.append(g);
    }
}

ThemeQt::ThemeQt(QString name)
: name_(std::move(name))
{
    const char* def[16] = {
            "#000000", "#cd0000", "#00cd00", "#cdcd00", "#0000ee", "#cd00cd", "#00cdcd", "#e5e5e5", "#7f7f7f", "#ff0000", "#00ff00", "#ffff00", "#5c5cff", "#ff00ff", "#00ffff", "#ffffff"};
    for (int i = 0; i < 16; ++i)
        ansi_[i] = QString::fromLatin1(def[i]);
}

void ThemeQt::setColors(const QString& fg, const QString& bg)
{
    fg_ = fg;
    bg_ = bg;
}

QStringList ThemeQt::ansiColors() const
{
    QStringList out;
    for (int i = 0; i < 16; ++i)
        out << ansi_[i];
    return out;
}

WorkspaceLayoutQt::WorkspaceLayoutQt(QString name)
: name_(std::move(name))
{
}

void WorkspaceLayoutQt::addDock(const models::DockPaneSpec& dock)
{
    for (int i = 0; i < docks_.size(); ++i) {
        if (docks_.at(i).id == dock.id) {
            docks_[i] = dock;
            return;
        }
    }
    docks_.append(dock);
}

void WorkspaceLayoutQt::removeDock(const QString& id)
{
    for (int i = 0; i < docks_.size(); ++i) {
        if (docks_.at(i).id == id) {
            docks_.removeAt(i);
            return;
        }
    }
}

bool WorkspaceLayoutQt::hasDock(const QString& id) const
{
    for (const models::DockPaneSpec& d : docks_) {
        if (d.id == id)
            return true;
    }
    return false;
}

QJsonObject WorkspaceLayoutQt::toJson() const
{
    QJsonObject obj;
    obj["name"] = name_;
    QJsonArray docks;
    for (const models::DockPaneSpec& d : docks_) {
        QJsonObject o;
        o["id"] = d.id;
        o["title"] = d.title;
        o["visible"] = d.visible;
        o["position"] = d.position;
        docks.append(o);
    }
    obj["docks"] = docks;
    obj["gauges"] = gauges_.toJson();
    QJsonObject theme;
    theme["name"] = theme_.name();
    theme["fg"] = theme_.fg();
    theme["bg"] = theme_.bg();
    theme["highContrast"] = theme_.highContrast();
    obj["theme"] = theme;
    return obj;
}

bool WorkspaceLayoutQt::fromJson(const QJsonObject& obj)
{
    name_ = obj.value("name").toString();
    if (name_.isEmpty())
        return false;
    docks_.clear();
    const QJsonArray docks = obj.value("docks").toArray();
    for (const auto& v : docks) {
        if (!v.isObject())
            continue;
        const QJsonObject o = v.toObject();
        models::DockPaneSpec d;
        d.id = o.value("id").toString();
        if (d.id.isEmpty())
            continue;
        d.title = o.value("title").toString();
        d.visible = o.value("visible").toBool(true);
        d.position = o.value("position").toString(QStringLiteral("right"));
        docks_.append(d);
    }
    gauges_.fromJson(obj.value("gauges").toArray());
    const QJsonObject theme = obj.value("theme").toObject();
    theme_.setName(theme.value("name").toString(QStringLiteral("default")));
    theme_.setColors(theme.value("fg").toString(QStringLiteral("#d0d0d0")), theme.value("bg").toString(QStringLiteral("#1e1e1e")));
    theme_.setHighContrast(theme.value("highContrast").toBool(false));
    return true;
}

} // namespace wiremudder::ui
