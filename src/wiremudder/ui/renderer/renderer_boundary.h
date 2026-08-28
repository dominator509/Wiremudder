// WireMudder Retro Renderer Boundary (EP-025 M3)
//
// Retro Renderer, Diorama, and Visual Emits pane surface (WM-FEAT-0069,
// WM-FEAT-0070, WM-FEAT-0071, WM-FEAT-0072, WM-FEAT-0073, WM-FEAT-0074,
// WM-FEAT-0077, WM-FEAT-0185, WM-FEAT-0207, WM-FEAT-0208, WM-FEAT-0209,
// WM-FEAT-0210; SPEC-016, SPEC-004, SPEC-012, SPEC-022). Shows:
//   - Renderer mode (disabled, static, low-power, no-animation,
//     animated, text-only).
//   - Bounded emit queue with drop/coalesce counters.
//   - Visual emits with visible confidence when inferred.
//   - Room backdrop / style capsule selection from World Bible.
//   - Asset pack provenance (license, hash, signature/local source).
//   - Clickable exits (visible; clicking records a proposal request
//     only — the command-safety gate performs the send).
// The pane is a passive observer: it displays data and surfaces user
// intent (click exit) as request flags; it NEVER sends commands and has
// no command path of its own. Raw text remains visible and
// authoritative (SPEC-016-R04).
//
// States (SPEC-025): Loading, Ready, Disabled, Denied, Degraded,
// Canceled, Unavailable, Error. Renderer worker failure disables
// immersion and preserves text gameplay (WM-SPEC-016-R10).
#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

namespace wiremudder::ui {

enum class RendererPaneState {
    Loading,
    Ready,
    Disabled,
    Denied,
    Degraded,
    Canceled,
    Unavailable,
    Error,
};

// One visual emit (visible confidence when inferred).
struct RendererEmitQt
{
    QString id;
    QString kind; // npc | mob | animal | player | pvp-visible | item
                  // | spell | combat | movement | door | weather
                  // | ambience | room-event
    QString label;
    int confidence = 0; // 0..100
    bool inferred = false;
    bool critical = false;
    QString provenance;
};

// One asset pack manifest entry (provenance-aware).
struct AssetPackQt
{
    QString id;
    QString pack;
    QString license;
    QString provenance;
    QString sha256;
    bool signedOrLocal = false;
    QStringList permissions;
};

// One style capsule from World Bible.
struct StyleCapsuleQt
{
    QString id;
    QStringList roomIds;
    QStringList palette;
    QString provenance;
};

// One clickable exit (visible exits cannot spoof trusted commands).
struct ClickableExitQt
{
    QString id;
    QString direction;
    QString targetRoom;
    bool visible = false;
};

// Retro Renderer pane. Model-side Qt surface; no QWidget dependency.
// Passive: never sends commands, never grants itself authority, raw
// text remains authoritative.
class RendererPaneQt
{
public:
    explicit RendererPaneQt();

    RendererPaneState state() const { return state_; }
    void setState(RendererPaneState s);
    QString stateLabel() const;

    QString mode() const { return mode_; }
    void setMode(const QString& m) { mode_ = m; }

    void setQueueLen(int n) { queueLen_ = n; }
    int queueLen() const { return queueLen_; }
    void setDrops(quint64 d) { drops_ = d; }
    quint64 drops() const { return drops_; }
    void setCoalesces(quint64 c) { coalesces_ = c; }
    quint64 coalesces() const { return coalesces_; }
    void setFrozen(bool f) { frozen_ = f; }
    bool frozen() const { return frozen_; }

    void setEmits(const QVector<RendererEmitQt>& e) { emits_ = e; }
    int emitCount() const { return emits_.size(); }
    const QVector<RendererEmitQt>& emits() const { return emits_; }

    void setPacks(const QVector<AssetPackQt>& p) { packs_ = p; }
    int packCount() const { return packs_.size(); }
    const QVector<AssetPackQt>& packs() const { return packs_; }

    void setCapsules(const QVector<StyleCapsuleQt>& c) { capsules_ = c; }
    int capsuleCount() const { return capsules_.size(); }
    const QVector<StyleCapsuleQt>& capsules() const { return capsules_; }

    void setExits(const QVector<ClickableExitQt>& e) { exits_ = e; }
    int exitCount() const { return exits_.size(); }
    const QVector<ClickableExitQt>& exits() const { return exits_; }
    // User intent: click an exit. The pane only records the request;
    // the command-safety gate performs the send.
    void requestExit(const QString& id) { exitRequested_ = id; }
    QString exitRequested() const { return exitRequested_; }

    // Passive by construction; never touches terminal or command path.
    bool isPassive() const { return true; }

    // No command path exists on this boundary (no hidden auto-send).
    bool canSendCommand() const { return false; }
    bool canEditGates() const { return false; }

    QString lastMessage() const { return lastMessage_; }
    void setLastMessage(const QString& m) { lastMessage_ = m; }

    void clear()
    {
        emits_.clear();
        packs_.clear();
        capsules_.clear();
        exits_.clear();
        exitRequested_.clear();
        queueLen_ = 0;
        drops_ = 0;
        coalesces_ = 0;
        frozen_ = false;
    }

private:
    RendererPaneState state_ = RendererPaneState::Unavailable;
    QString mode_ = QStringLiteral("static");
    int queueLen_ = 0;
    quint64 drops_ = 0;
    quint64 coalesces_ = 0;
    bool frozen_ = false;
    QVector<RendererEmitQt> emits_;
    QVector<AssetPackQt> packs_;
    QVector<StyleCapsuleQt> capsules_;
    QVector<ClickableExitQt> exits_;
    QString exitRequested_;
    QString lastMessage_;
};

} // namespace wiremudder::ui
