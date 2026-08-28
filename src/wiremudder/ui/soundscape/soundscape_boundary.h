// WireMudder Soundscape Engine and Audio Studio Boundary (EP-026 M3)
//
// Room, area, combat, boss, weather, death, victory, ambience, and
// user-authored soundscape bindings pane surface (WM-FEAT-0075,
// WM-FEAT-0076; SPEC-016, SPEC-004, SPEC-015, SPEC-022). Shows:
//   - All binding classes with independent volume and disable controls.
//   - Profile-scoped studio controls (volume, disable).
//   - Studio mode: disabled, muted, manual, auto.
//   - Current soundscape, bounded queue, load-shed and coalesce
//     counters, transition state (bounded and cancelable).
//   - Asset provenance (license, provenance, hash) for every loaded
//     pack; protected or unlicensed packs are never listed.
// The pane is a passive observer: it displays state and surfaces user
// intent (volume/disable/transition request) as request flags; it
// NEVER sends commands and has no command path of its own. Audio
// failure degrades to silence and text gameplay is always preserved
// (WM-SPEC-016-R10).
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded,
// Canceled, Unavailable, Error.
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

enum class SoundscapePaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// Studio mode (text-preserving degradation surface).
enum class SoundscapeModeQt {
    Disabled,
    Muted,
    Manual,
    Auto,
};

// One visible soundscape binding (WM-SPEC-016-R08).
struct SoundscapeBindingQt
{
    QString kind; // room|area|combat|boss|weather|death|victory|ambience|user-authored
    QString assetId;
    int volume = 70;     // independent, 0..=100
    bool enabled = true; // independent disable
    QString userAuthor;
};

// Profile-scoped studio controls (obligation 3).
struct SoundscapeProfileQt
{
    QString profile;
    int volume = 70; // 0..=100
    bool disabled = false;
};

// One loaded asset pack with provenance (WM-SPEC-016-R09).
struct SoundscapeAssetQt
{
    QString id;
    QString license;
    QString provenance;
    QString sha256;
    bool userLocal = false;
};

// Soundscape pane. Model-side Qt surface; no QWidget dependency.
// Passive: never sends commands, never grants itself authority.
class SoundscapePaneQt
{
public:
    explicit SoundscapePaneQt();

    SoundscapePaneState state() const { return state_; }
    void setState(SoundscapePaneState s);
    QString stateLabel() const;

    // Bindings with independent volume/disable.
    void setBindings(const QVector<SoundscapeBindingQt>& b) { bindings_ = b; }
    int bindingCount() const { return bindings_.size(); }
    const QVector<SoundscapeBindingQt>& bindings() const { return bindings_; }
    // User intent: adjust a binding. The pane only records the request.
    void requestSetBindingVolume(const QString& kind, int volume)
    {
        bindingVolumeRequested_ = kind;
        bindingVolumeValue_ = volume;
    }
    QString bindingVolumeRequested() const { return bindingVolumeRequested_; }
    int bindingVolumeValue() const { return bindingVolumeValue_; }
    void requestSetBindingEnabled(const QString& kind, bool enabled)
    {
        bindingEnabledRequested_ = kind;
        bindingEnabledValue_ = enabled;
    }
    QString bindingEnabledRequested() const { return bindingEnabledRequested_; }
    bool bindingEnabledValue() const { return bindingEnabledValue_; }

    // Profile-scoped studio controls.
    void setProfiles(const QVector<SoundscapeProfileQt>& p) { profiles_ = p; }
    int profileCount() const { return profiles_.size(); }
    const QVector<SoundscapeProfileQt>& profiles() const { return profiles_; }

    // Studio mode.
    SoundscapeModeQt mode() const { return mode_; }
    void setMode(SoundscapeModeQt m) { mode_ = m; }
    QString modeLabel() const;

    // Observable engine state.
    void setCurrent(const QString& c) { current_ = c; }
    QString current() const { return current_; }
    void setQueueLen(int n) { queueLen_ = n; }
    int queueLen() const { return queueLen_; }
    void setLoadShed(int n) { loadShed_ = n; }
    int loadShed() const { return loadShed_; }
    void setCoalesced(int n) { coalesced_ = n; }
    int coalesced() const { return coalesced_; }
    void setTransitionActive(bool a) { transitionActive_ = a; }
    bool transitionActive() const { return transitionActive_; }
    void setTransitionRemainingMs(int ms) { transitionRemainingMs_ = ms; }
    int transitionRemainingMs() const { return transitionRemainingMs_; }
    // User intent: start or cancel a transition. Records requests only.
    void requestTransition(const QString& kind, int durationMs)
    {
        transitionRequested_ = kind;
        transitionDurationMs_ = durationMs;
    }
    QString transitionRequested() const { return transitionRequested_; }
    int transitionDurationMs() const { return transitionDurationMs_; }
    void requestCancelTransition() { cancelTransitionRequested_ = true; }
    bool cancelTransitionRequested() const { return cancelTransitionRequested_; }

    // Asset provenance display.
    void setAssets(const QVector<SoundscapeAssetQt>& a) { assets_ = a; }
    int assetCount() const { return assets_.size(); }
    const QVector<SoundscapeAssetQt>& assets() const { return assets_; }

    // Degradation state: audio failure disables immersion and preserves
    // text gameplay.
    void setFailed(bool f) { failed_ = f; }
    bool failed() const { return failed_; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No command path exists on this boundary (no hidden auto-send).
    bool canSendCommand() const { return false; }
    bool canEditGates() const { return false; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    void clear()
    {
        bindings_.clear();
        profiles_.clear();
        assets_.clear();
        bindingVolumeRequested_.clear();
        bindingVolumeValue_ = 0;
        bindingEnabledRequested_.clear();
        bindingEnabledValue_ = false;
        transitionRequested_.clear();
        transitionDurationMs_ = 0;
        cancelTransitionRequested_ = false;
        current_.clear();
        queueLen_ = 0;
        loadShed_ = 0;
        coalesced_ = 0;
        transitionActive_ = false;
        transitionRemainingMs_ = 0;
        failed_ = false;
    }

private:
    SoundscapePaneState state_ = SoundscapePaneState::Unavailable;
    SoundscapeModeQt mode_ = SoundscapeModeQt::Auto;
    QVector<SoundscapeBindingQt> bindings_;
    QVector<SoundscapeProfileQt> profiles_;
    QVector<SoundscapeAssetQt> assets_;
    QString bindingVolumeRequested_;
    int bindingVolumeValue_ = 0;
    QString bindingEnabledRequested_;
    bool bindingEnabledValue_ = false;
    QString transitionRequested_;
    int transitionDurationMs_ = 0;
    bool cancelTransitionRequested_ = false;
    QString current_;
    int queueLen_ = 0;
    int loadShed_ = 0;
    int coalesced_ = 0;
    bool transitionActive_ = false;
    int transitionRemainingMs_ = 0;
    bool failed_ = false;
    QString lastMessage_;
};

} // namespace wiremudder::ui
