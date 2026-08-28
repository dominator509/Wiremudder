// WireMudder Telemetry, Replay, and Diagnostic Bundles Boundary (EP-028 M3)
//
// Diagnostics pane surface (WM-FEAT-0128, WM-FEAT-0132, WM-FEAT-0221,
// WM-FEAT-0223, WM-FEAT-0224, WM-FEAT-0225, WM-FEAT-0227; SPEC-019,
// SPEC-023, SPEC-025, SPEC-026). Shows:
//   - Telemetry enable state (off by default) with capture on/off.
//   - Bounded ring buffer occupancy (events/capacity) and drop count.
//   - Severity counters (critical, error, warn, info, debug).
//   - Correlation ID and fingerprint of the most recent event.
//   - Session replay summary and deterministic replay preview.
//   - Diagnostic bundle: content hash, event count, bytes, preview;
//     approval flag that is always false until explicit user action.
//   - Sanitized fixture generation with approval-scoped inclusion.
// The pane is a passive observer: it displays state and surfaces user
// intent (enable/disable capture, approve bundle, generate fixture) as
// request flags; it NEVER submits bundles externally and has no egress
// path of its own. Telemetry stays off externally by default and no
// secret or private data is ever displayed.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded,
// Canceled, Unavailable, Error.
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

enum class DiagnosticsPaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// One telemetry event row (redacted; SPEC-019-R02).
struct TelemetryEventQt {
    QString eventId;
    QString subsystem;
    QString severity;
    QString fingerprint;
    QString correlationId;
    QString classification;
    bool redacted = false;
};

// Session replay summary (SPEC-019-R04).
struct ReplaySummaryQt {
    QString sessionId;
    QString app;
    QString gitSha;
    int eventCount = 0;
    QString contentHash;
};

// Diagnostic bundle display (SPEC-019-R03, SPEC-026-R07).
struct DiagnosticBundleQt {
    QString bundleId;
    QString contentSha256;
    int eventCount = 0;
    int bytes = 0;
    QString preview;
    bool approvedForSubmission = false;
};

// Diagnostics pane. Model-side Qt surface; no QWidget dependency.
// Passive: never submits bundles, never enables capture on its own.
class DiagnosticsPaneQt {
public:
    explicit DiagnosticsPaneQt();

    DiagnosticsPaneState state() const { return state_; }
    void setState(DiagnosticsPaneState s);
    QString stateLabel() const;

    // Telemetry capture state (off by default; SPEC-019-R01).
    bool captureEnabled() const { return captureEnabled_; }
    void setCaptureEnabled(bool e) { captureEnabled_ = e; }
    // User intent: flip capture. The pane only records the request.
    void requestSetCaptureEnabled(bool e) { captureRequested_ = e; }
    bool captureRequested() const { return captureRequested_; }

    // Ring buffer occupancy (bounded; WM-FEAT-0223).
    void setRingOccupancy(int events, int capacity) { ringEvents_ = events; ringCapacity_ = capacity; }
    int ringEvents() const { return ringEvents_; }
    int ringCapacity() const { return ringCapacity_; }
    void setDropped(quint64 dropped) { dropped_ = dropped; }
    quint64 dropped() const { return dropped_; }
    void setCoalesced(quint64 coalesced) { coalesced_ = coalesced; }
    quint64 coalesced() const { return coalesced_; }

    // Severity counters (WM-FEAT-0225).
    void setSeverityCounts(int critical, int error, int warn, int info, int debug) {
        critical_ = critical; error_ = error; warn_ = warn; info_ = info; debug_ = debug;
    }
    int critical() const { return critical_; }
    int error() const { return error_; }
    int warn() const { return warn_; }
    int info() const { return info_; }
    int debug() const { return debug_; }

    // Recent redacted events.
    void setEvents(const QVector<TelemetryEventQt>& e) { events_ = e; }
    int eventCount() const { return events_.size(); }
    const QVector<TelemetryEventQt>& events() const { return events_; }

    // Session replay.
    void setReplay(const ReplaySummaryQt& r) { replay_ = r; }
    const ReplaySummaryQt& replay() const { return replay_; }

    // Diagnostic bundle preview/export (preview matches export).
    void setBundle(const DiagnosticBundleQt& b) { bundle_ = b; }
    const DiagnosticBundleQt& bundle() const { return bundle_; }
    // User intent: approve the bundle for submission. Records request
    // only; the pane itself never submits.
    void requestApproveBundle() { bundleApprovalRequested_ = true; }
    bool bundleApprovalRequested() const { return bundleApprovalRequested_; }

    // Sanitized fixture generation (WM-FEAT-0128, SPEC-019-R05).
    void setFixtureReady(bool r) { fixtureReady_ = r; }
    bool fixtureReady() const { return fixtureReady_; }
    void requestGenerateFixture(bool approvedVoice) { fixtureRequested_ = true; fixtureApprovedVoice_ = approvedVoice; }
    bool fixtureRequested() const { return fixtureRequested_; }
    bool fixtureApprovedVoice() const { return fixtureApprovedVoice_; }

    // Telemetry remains off externally by default; no secret shown.
    bool captureEnabledByDefault() const { return false; }
    bool showsRedactedOnly() const { return true; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No egress path exists on this boundary.
    bool canSubmitBundle() const { return false; }
    bool canSendCommand() const { return false; }
    bool canEditGates() const { return false; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    void clear() {
        captureEnabled_ = false;
        captureRequested_ = false;
        ringEvents_ = 0;
        ringCapacity_ = 0;
        dropped_ = 0;
        coalesced_ = 0;
        critical_ = 0; error_ = 0; warn_ = 0; info_ = 0; debug_ = 0;
        events_.clear();
        replay_ = ReplaySummaryQt();
        bundle_ = DiagnosticBundleQt();
        bundleApprovalRequested_ = false;
        fixtureReady_ = false;
        fixtureRequested_ = false;
        fixtureApprovedVoice_ = false;
    }

private:
    DiagnosticsPaneState state_ = DiagnosticsPaneState::Unavailable;
    bool captureEnabled_ = false;
    bool captureRequested_ = false;
    int ringEvents_ = 0;
    int ringCapacity_ = 0;
    quint64 dropped_ = 0;
    quint64 coalesced_ = 0;
    int critical_ = 0;
    int error_ = 0;
    int warn_ = 0;
    int info_ = 0;
    int debug_ = 0;
    QVector<TelemetryEventQt> events_;
    ReplaySummaryQt replay_;
    DiagnosticBundleQt bundle_;
    bool bundleApprovalRequested_ = false;
    bool fixtureReady_ = false;
    bool fixtureRequested_ = false;
    bool fixtureApprovedVoice_ = false;
    QString lastMessage_;
};

} // namespace wiremudder::ui
