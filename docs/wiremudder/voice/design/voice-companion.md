# Voice Companion and Voice Macros — Design (EP-024 M3)

## Purpose

Push-to-talk voice, local-first STT/TTS, optional approved remote
providers, visible mic state, voice macros through Action Proposals,
agent voice styles, cancellation, subtitles, and load shedding
(SPEC-015, SPEC-009, SPEC-010, SPEC-017, SPEC-022).

## Architecture

- `wirecore/crates/wire-voice/` — namespaced new code: `VoiceCompanion`
  (state machine, bounded queue, command-safety gated macros, licensed
  styles, consent-gated remote speech, subtitles, degrade-to-text),
  `VoiceMacro` -> `ActionProposal` (SPEC-009), `RemoteSpeechPolicy`,
  `ConsentReceipt`, `VoiceStyle`, `SpeechJob`, `SubtitleLine`.
- `src/wiremudder/ui/voice/voice_boundary.{h,cpp}` — model-side Qt
  surface following the copilot/soul/autopilot/assistance/power-tools
  pane pattern. Passive: no command path, no gate editing, mic state
  always visible. Compiled into the actual client via
  `src/CMakeLists.txt` (discovered amendment WM-SRC-000155).
- `schemas/wiremudder/voice/` — companion-state, macro, style,
  transcript, remote-policy JSON schemas (versioned, v1).
- `config/wiremudder/voice/voice.yaml` — local-first configuration;
  wake phrase disabled by default; remote providers unconfigured.

## Key invariants

1. Mic state is always visible (off, listening, speaking, barge-in,
   error, disabled). No hidden capture state exists.
2. Voice macros produce Action Proposals through the same deterministic
   command-safety gate as every other automation (WM-SPEC-009-R02).
   The voice subsystem never auto-sends and never self-approves.
3. Remote speech requires configured provider + privacy policy +
   redaction + scoped revocable consent (WM-SPEC-015-R04,
   WM-SPEC-010-R08/R09). Local Only Lockdown blocks remote speech.
4. Speech queue is bounded (64) and cancelable; noncritical P3 work is
   shed under load; barge-in cancels synthesis; combat suppresses
   narration (SPEC-004-R04, WM-SPEC-015-R08).
5. Worker crash or provider outage degrades to text without touching
   terminal, input, connection, or emergency stop (WM-SPEC-015-R10).
6. Voice styles are licensed configuration profiles; protected
   characters/celebrities require lawful authorization
   (WM-SPEC-015-R07).
7. Subtitles and transcripts: configurable retention (bounded 512),
   private content suppressed by default (WM-SPEC-015-R09).

## Exact commands and observed behavior

- `cargo test --manifest-path wirecore/crates/wire-voice/Cargo.toml`
  -> `test result: ok. 18 passed`
- `cargo run --example e2e_voice` -> `E2E voice: ok` with mic state,
  Action Proposal, remote denial/consent, barge-in, degrade-to-text,
  and subtitle privacy lines.
- Boundary compile vs real Qt6 (`/opt/qt/6.8.2/gcc_64`):
  `c++ -std=c++20 -fPIC -I/root/wiremudder-repo -I$QT/include
  -I$QT/include/QtCore -c src/wiremudder/ui/voice/voice_boundary.cpp`
  -> object produced; boundary asserts `canSendCommand()==false`,
  `canEditGates()==false`, `isPassive()==true`.

## Rollback

- `git checkout -- src/CMakeLists.txt` reverts the single inherited
  edit; deleting `src/wiremudder/ui/voice/` removes the boundary.
- Removing `wirecore/crates/wire-voice/`, `schemas/wiremudder/voice/`,
  `config/wiremudder/voice/` reverts the new code (all namespaced).
- No migration or external provider state is touched; voice is local
  and optional. Fallback: ship voice disabled with one certified local
  push-to-talk provider; omit wake phrase and remote speech until
  separately certified.
