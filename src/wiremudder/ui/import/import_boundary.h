// WireMudder Import and Migration Pane Boundary (EP-030)
//
// Passive surface for import planning, migration reports, conflict
// resolution, and rollback status (WM-FEAT-0120; SPEC-021, SPEC-008,
// SPEC-020). Shows:
//   - Import plan review: source format, hash, provenance, backup path.
//   - Migration report counts: imported, warnings, unsupported, conflicts.
//   - Disabled-automation banner: every imported item starts disabled and
//     requires explicit review before enablement (WM-SPEC-021-R04).
//   - Rollback status and diagnostics path (WM-SPEC-021-R09).
// The pane is a passive observer: it displays plan/report data and
// surfaces user intent (review item, approve migration) as request flags;
// it NEVER executes imports, NEVER enables automation, and has no mutation
// path. Import execution remains an explicit operator action behind the
// crate boundary.
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded,
// Canceled, Unavailable, Error. The pane never blocks text gameplay.
#pragma once

#include <QString>

namespace wiremudder::ui::import {

enum class PaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

struct ImportSummary
{
    bool valid = false;
    QString source_format;
    QString source_hash;
    int imported_count = 0;
    int warning_count = 0;
    int unsupported_count = 0;
    int conflict_count = 0;
    bool automation_disabled = true;
    QString backup_path;
    QString rollback_path;
    QString diagnostics_path;
};

// Passive view-model: the pane only reflects the real crate-produced
// plan/report; it never mutates or executes anything itself.
class ImportPaneModel
{
public:
    ImportPaneModel() = default;

    void setSummary(const ImportSummary& summary) { m_summary = summary; }
    ImportSummary summary() const { return m_summary; }

    void setState(PaneState state) { m_state = state; }
    PaneState state() const { return m_state; }

    // Request flags surfaced to the operator; the pane itself never acts.
    bool reviewRequested() const { return m_review_requested; }
    void requestReview() { m_review_requested = true; }

    // Passive-surface invariants (EP-030).
    bool isPassive() const { return true; }
    bool canExecuteImport() const { return false; }
    bool canEnableAutomation() const { return false; }
    bool canSendCommand() const { return false; }
    bool canAccessSecrets() const { return false; }
    bool canEgress() const { return false; }
    bool automationDisabledByDefault() const { return true; }

    // Reset per load; no mutation of any imported data.
    void reset()
    {
        m_summary = ImportSummary{};
        m_state = PaneState::Loading;
        m_review_requested = false;
    }

private:
    ImportSummary m_summary;
    PaneState m_state = PaneState::Loading;
    bool m_review_requested = false;
};

} // namespace wiremudder::ui::import
