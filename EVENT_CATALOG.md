# WireMudder Event Catalog

## Gameplay Observations

RoomSeen, ExitSeen, MobSeen, PlayerSeen, AnimalSeen, PKerOrPvPerSeen, ItemSeen, QuestClueSeen, PromptSeen, HealthChanged, CombatStarted, CombatEnded, CommandSucceeded, CommandFailed, SocialMessageSeen, PrivateMessageSeenRedacted, and RendererEmitCandidate.

## Lifecycle

AppStarted, ProfileOpened, SessionConnecting, SessionConnected, SessionDisconnected, SessionReconnecting, WireCoreStarting, WireCoreReady, WireCoreDegraded, WireCoreStopped, WorkerReady, WorkerFailed, and EmergencyStopChanged.

## Policy and Action

ConsentChanged, PrivacyModeChanged, RedactionApplied, RoutingProfileSelected, RoutingValidationChanged, ActionProposed, ActionDenied, ActionApproved, ActionQueued, ActionSent, ActionCanceled, CommandPolicyChanged, and AutomationPaused.

## AI and Memory

ContextCapsuleCreated, ProviderRouted, ProviderStarted, ProviderStreamed, ProviderCanceled, ProviderFailed, SuggestionCreated, MemoryProposed, MemoryAccepted, MemoryCorrected, MemorySuperseded, SnapshotCreated, and SnapshotRestored.

## Voice and Immersion

MicStateChanged, SpeechRecognized, SpeechSynthesisStarted, SpeechCanceled, VoiceMacroProposed, RendererBackdropChanged, RendererEmitQueued, RendererEmitDropped, SoundscapeChanged, and ImmersionDegraded.

## Operations

TelemetryCaptured, DiagnosticPrepared, ReplayStarted, ReplayMismatch, BugCaseChanged, PackagePermissionChanged, ImportCompleted, UpdateChecked, UpdateRejected, UpdateInstalled, UpdateRolledBack, and ReleaseEvidenceRecorded.

EP-004 assigns stable schema IDs and versions. This document does not authorize unversioned event strings in code.
