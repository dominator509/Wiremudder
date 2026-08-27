// WireMudder Workspace Boundary (EP-012 M2)
//
// Workspace layouts, panes, status bars/gauges, and themes
// (WM-FEAT-0012, WM-FEAT-0021, WM-SPEC-007-R04). A layout is a named,
// per-profile persistable collection of dock panes and gauges with one
// active theme. Theme contrast is checked for non-color readability
// (WM-SPEC-027-R07).
#pragma once

#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QString>
#include <utility>

#include "src/wiremudder/models/workspace_models.h"

namespace wiremudder::ui {

// Status bar / gauge registry (WM-FEAT-0012).
class StatusGaugeQt {
public:
    void set(const models::StatusGauge& g);
    bool has(const QString& id) const;
    QString value(const QString& id) const;
    QStringList ids() const;
    QJsonArray toJson() const;
    void fromJson(const QJsonArray& arr);
    int count() const { return gauges_.size(); }

private:
    QList<models::StatusGauge> gauges_;
};

// Theme store with contrast check (WM-FEAT-0021, WM-SPEC-027-R07).
class ThemeQt {
public:
    explicit ThemeQt(QString name = QStringLiteral("default"));
    QString name() const { return name_; }
    void setName(const QString& name) { name_ = name; }
    QString fg() const { return fg_; }
    QString bg() const { return bg_; }
    void setColors(const QString& fg, const QString& bg);
    // Non-color state: high-contrast theme remains readable.
    bool highContrast() const { return highContrast_; }
    void setHighContrast(bool v) { highContrast_ = v; }
    QStringList ansiColors() const;

private:
    QString name_;
    QString fg_ = QStringLiteral("#d0d0d0");
    QString bg_ = QStringLiteral("#1e1e1e");
    bool highContrast_ = false;
    QString ansi_[16];
};

// Named, persistable workspace layout (WM-SPEC-007-R04).
class WorkspaceLayoutQt {
public:
    explicit WorkspaceLayoutQt(QString name = QStringLiteral("default"));
    QString name() const { return name_; }
    void addDock(const models::DockPaneSpec& dock);
    void removeDock(const QString& id);
    QList<models::DockPaneSpec> docks() const { return docks_; }
    bool hasDock(const QString& id) const;
    StatusGaugeQt& gauges() { return gauges_; }
    const StatusGaugeQt& gauges() const { return gauges_; }
    ThemeQt& theme() { return theme_; }
    const ThemeQt& theme() const { return theme_; }
    // Per-profile persistence (WM-SPEC-007-R04).
    QJsonObject toJson() const;
    bool fromJson(const QJsonObject& obj);

private:
    QString name_;
    QList<models::DockPaneSpec> docks_;
    StatusGaugeQt gauges_;
    ThemeQt theme_;
};

} // namespace wiremudder::ui
