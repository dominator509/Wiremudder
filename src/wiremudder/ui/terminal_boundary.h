// WireMudder Terminal Boundary (EP-012 M2)
//
// Terminal authority (WM-SPEC-007-R03): raw text is appended to the
// model before any decoration and is never hidden or delayed. The pane
// owns a bounded scrollback ring; capture panes subscribe to the same
// stream without mutating it. Command history is bounded and persisted.
#pragma once

#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QString>

#include "src/wiremudder/models/workspace_models.h"

namespace wiremudder::ui {

// Bounded scrollback terminal pane (WM-FEAT-0001, WM-FEAT-0003).
class TerminalPaneQt
{
public:
    explicit TerminalPaneQt(int maxLines = 2000);
    // Append raw text; invariant: raw bytes are stored unmodified and
    // the line is visible immediately (never delayed, never decorated).
    void appendRaw(const QString& raw);
    void clear();
    int lineCount() const;
    // Raw text of the newest line, or empty string.
    QString lastLine() const;
    // Full raw snapshot, oldest to newest.
    QStringList snapshot() const;
    int maxLines() const { return maxLines_; }
    bool overflowDropped() const { return overflowDropped_; }

private:
    QList<models::TerminalLine> lines_;
    int maxLines_;
    int nextSeq_ = 1;
    bool overflowDropped_ = false;
};

// Bounded command history (WM-FEAT-0004) with up/down navigation.
class CommandHistoryQt
{
public:
    explicit CommandHistoryQt(int maxEntries = 500);
    void add(const QString& command);
    QString up();
    QString down();
    QString current() const { return current_; }
    QStringList all() const;
    int count() const { return entries_.size(); }
    // Persistence (per-profile, WM-SPEC-007-R04).
    QJsonArray toJson() const;
    void fromJson(const QJsonArray& arr);

private:
    QList<QString> entries_;
    int maxEntries_;
    int index_ = -1; // -1 = at the "new" position
    QString current_;
};

// Capture/output pane (WM-FEAT-0011). Subscribes to the raw stream and
// keeps a bounded copy of matching lines; never alters the source.
class CapturePaneQt
{
public:
    explicit CapturePaneQt(int maxCaptured = 500);
    void setFilter(const models::CaptureFilter& filter);
    const models::CaptureFilter& filter() const { return filter_; }
    void ingest(const QString& raw);
    QStringList captured() const;
    int count() const { return captured_.size(); }

private:
    models::CaptureFilter filter_;
    QList<QString> captured_;
    int maxCaptured_;
};

} // namespace wiremudder::ui
