// WireMudder Workspace Models (EP-012 M2)
//
// Pure data structs shared by the UI boundaries. No Qt dependency in
// this header: the models are value types that describe terminal lines,
// dock panes, themes, gauges, and capture filters.
#pragma once

#include <QString>
#include <QVector>

namespace wiremudder::models {

// One raw terminal line (WM-FEAT-0001/0003). `raw` is the exact text
// received; decoration is applied by renderers, never by the model.
struct TerminalLine
{
    int seq = 0;     // monotonically increasing line number
    QString raw;     // raw text, unmodified
    qint64 atMs = 0; // arrival timestamp (ms since epoch)
};

// Dock pane specification (WM-FEAT-0011, WM-SPEC-007-R04).
struct DockPaneSpec
{
    QString id;
    QString title;
    bool visible = true;
    QString position = QStringLiteral("right"); // left|right|top|bottom
};

// Theme specification (WM-FEAT-0021, WM-SPEC-027-R07 contrast).
struct ThemeSpec
{
    QString name;
    QString fg;
    QString bg;
    QString ansi[16];
    bool highContrast = false; // non-color state still readable
};

// Status bar gauge (WM-FEAT-0012).
struct StatusGauge
{
    QString id;
    QString label;
    QString value;
    double min = 0.0;
    double max = 100.0;
};

// Capture pane filter (WM-FEAT-0011). A line is captured when the
// predicate (substring match) holds.
struct CaptureFilter
{
    QString id;
    QString match; // substring match against raw line
    bool caseSensitive = false;
};

} // namespace wiremudder::models
