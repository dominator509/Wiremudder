// WireMudder Terminal Boundary (EP-012 M2) - implementation.
#include "src/wiremudder/ui/terminal_boundary.h"

namespace wiremudder::ui {

TerminalPaneQt::TerminalPaneQt(int maxLines) : maxLines_(maxLines) {}

void TerminalPaneQt::appendRaw(const QString& raw) {
    models::TerminalLine line;
    line.seq = nextSeq_++;
    line.raw = raw;
    lines_.append(line);
    if (lines_.size() > maxLines_) {
        lines_.removeFirst();
        overflowDropped_ = true;
    }
}

void TerminalPaneQt::clear() {
    lines_.clear();
    nextSeq_ = 1;
    overflowDropped_ = false;
}

int TerminalPaneQt::lineCount() const { return lines_.size(); }

QString TerminalPaneQt::lastLine() const {
    return lines_.isEmpty() ? QString() : lines_.last().raw;
}

QStringList TerminalPaneQt::snapshot() const {
    QStringList out;
    for (const models::TerminalLine& l : lines_) out << l.raw;
    return out;
}

CommandHistoryQt::CommandHistoryQt(int maxEntries) : maxEntries_(maxEntries) {}

void CommandHistoryQt::add(const QString& command) {
    if (command.isEmpty()) return;
    if (!entries_.isEmpty() && entries_.last() == command) return; // dedup consecutive
    entries_.append(command);
    if (entries_.size() > maxEntries_) entries_.removeFirst();
    index_ = -1;
    current_ = QString();
}

QString CommandHistoryQt::up() {
    if (entries_.isEmpty()) return QString();
    if (index_ < 0) {
        current_ = QString();
        index_ = entries_.size() - 1;
    } else if (index_ > 0) {
        --index_;
    }
    current_ = entries_.at(index_);
    return current_;
}

QString CommandHistoryQt::down() {
    if (entries_.isEmpty() || index_ < 0) return QString();
    if (index_ < entries_.size() - 1) {
        ++index_;
        current_ = entries_.at(index_);
    } else {
        index_ = -1;
        current_ = QString();
    }
    return current_;
}

QStringList CommandHistoryQt::all() const { return entries_; }

QJsonArray CommandHistoryQt::toJson() const {
    QJsonArray arr;
    for (const QString& e : entries_) arr.append(e);
    return arr;
}

void CommandHistoryQt::fromJson(const QJsonArray& arr) {
    entries_.clear();
    for (const auto& v : arr) {
        if (v.isString()) entries_.append(v.toString());
    }
    if (entries_.size() > maxEntries_) {
        while (entries_.size() > maxEntries_) entries_.removeFirst();
    }
    index_ = -1;
    current_ = QString();
}

CapturePaneQt::CapturePaneQt(int maxCaptured) : maxCaptured_(maxCaptured) {}

void CapturePaneQt::setFilter(const models::CaptureFilter& filter) {
    filter_ = filter;
    captured_.clear();
}

void CapturePaneQt::ingest(const QString& raw) {
    if (filter_.match.isEmpty()) return;
    const QString hay = filter_.caseSensitive ? raw : raw.toLower();
    const QString needle = filter_.caseSensitive ? filter_.match : filter_.match.toLower();
    if (hay.contains(needle)) {
        captured_.append(raw);
        if (captured_.size() > maxCaptured_) captured_.removeFirst();
    }
}

QStringList CapturePaneQt::captured() const { return captured_; }

} // namespace wiremudder::ui
