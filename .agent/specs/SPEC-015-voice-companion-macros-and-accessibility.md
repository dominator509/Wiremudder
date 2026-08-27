# SPEC-015: Voice Companion, Macros, and Accessibility

## Status

Accepted blueprint specification.

## Goal

Provide local-first conversational voice, push-to-talk, optional wake phrase, per-character and per-agent styles, command safety, subtitles, cancellation, and privacy controls.

## Canonical Terms

Voice Companion, STT, TTS, push-to-talk, wake phrase, voice macro, voice style, barge-in.

## Required Behavior

WM-SPEC-015-R01: Push-to-talk and hold-to-talk are the initial activation modes and microphone state is always visible.

WM-SPEC-015-R02: Wake phrase is optional, disabled by default, explicitly consented, and pauses under load or Local Only policy when its provider is not local.

WM-SPEC-015-R03: STT and TTS run outside the Mudlet process and cannot block terminal, input, connection, or emergency stop.

WM-SPEC-015-R04: Local providers are preferred; remote speech requires configured provider, privacy policy, redaction, and consent.

WM-SPEC-015-R05: Voice macros produce Action Proposals and pass the same deterministic command safety gates as other automation.

WM-SPEC-015-R06: Spoken room, map, quest, tactical, combat, help, and setup summaries disclose their source and respect privacy.

WM-SPEC-015-R07: Per-character and per-agent voice styles are licensed configuration profiles and cannot imitate protected characters or celebrities without lawful authorization.

WM-SPEC-015-R08: Barge-in cancels synthesis, noncritical speech is shortened or dropped under load, and combat can suppress narration.

WM-SPEC-015-R09: Subtitles and transcript controls are available, retention is configurable, and private content is suppressed by default.

WM-SPEC-015-R10: Voice failure, provider outage, or worker crash degrades to text without affecting gameplay.

## Inputs and Outputs

Inputs and outputs use canonical schemas, generated bindings where applicable, explicit profile and world scope, correlation, sensitivity, versioning, and source evidence. Free-form external payloads are normalized before they cross the owning boundary.

## Error States

Validation, consent, policy, authorization, unavailable, timeout, cancellation, conflict, security, compatibility, verification, and rollback errors follow SPEC-025. Ambiguity fails closed where authority, privacy, secrets, routing, updates, or data integrity are involved.

## Security and Privacy

- Microphone access is capability-scoped and auditable.

## Performance

- Speech queues are bounded and cancelable and may shed P3 work.

## Non-Goals

- Hidden microphone capture
- Protected voice cloning
- Voice bypass of command safety

## Required Tests

- Mic state UI
- Local STT/TTS proof
- Remote denial
- Barge-in timing
- Voice command confirmation
- Worker crash isolation

## Acceptance

All requirements for SPEC-015 have implemented tests at the paths in `.agent/requirements/VALIDATION_MATRIX.tsv`, every owning node has passed its verifier and proof, and no unresolved compatibility, security, performance, privacy, migration, or release contradiction remains.

## Traceability

Owning nodes: EP-006, EP-008, EP-023, EP-024, EP-031, EP-032. Machine trace: `.agent/requirements/VALIDATION_MATRIX.tsv`. Feature trace: `.agent/features/FEATURES.tsv`.
