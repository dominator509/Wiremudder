# Feature Index

Every enabled feature in the product and where it is documented.

Status: **required** = enabled in its profile; **research-decision-required** = not implemented, honestly labeled.


## AI (documented in [ai.md](ai.md))

- **WM-FEAT-0181** (required, ai): Mapper and Cartographer Agent
- **WM-FEAT-0182** (required, ai): Lore and Memory Curator Agent
- **WM-FEAT-0183** (required, ai): Quest Agent
- **WM-FEAT-0184** (required, ai): Tactical Agent
- **WM-FEAT-0185** (required, immersion): Renderer Scene Agent
- **WM-FEAT-0186** (required, immersion): Voice Companion Agent
- **WM-FEAT-0187** (required, developer): Contextual Help and Setup Coach Agent
- **WM-FEAT-0188** (required, core): Command Safety Agent
- **WM-FEAT-0189** (required, ai): Token Budget Agent
- **WM-FEAT-0190** (required, core): Privacy Firewall Agent

## AI and Memory (documented in [ai.md](ai.md))

- **WM-FEAT-0037** (required, full): local and remote AI provider adapters
- **WM-FEAT-0038** (required, full): AI Provider Router
- **WM-FEAT-0039** (required, full): privacy modes
- **WM-FEAT-0040** (required, full): Player Copilot
- **WM-FEAT-0041** (required, full): Guarded Autopilot
- **WM-FEAT-0042** (required, full): Soul.md personas
- **WM-FEAT-0043** (required, full): Soul.md Studio
- **WM-FEAT-0044** (required, full): Agent Skill Tree
- **WM-FEAT-0045** (required, full): Agent Council
- **WM-FEAT-0046** (required, full): AI Confidence Meter
- **WM-FEAT-0047** (required, full): AI `Why?` explanations
- **WM-FEAT-0048** (required, full): Context Distillation Engine
- **WM-FEAT-0049** (required, full): Token Budget Dashboard
- **WM-FEAT-0050** (required, full): World Brain
- **WM-FEAT-0051** (required, full): World Bible
- **WM-FEAT-0052** (required, full): RAG memory
- **WM-FEAT-0053** (required, full): Time Machine Memory
- **WM-FEAT-0054** (required, full): Quest Compass
- **WM-FEAT-0055** (required, full): Tactical HUD
- **WM-FEAT-0056** (required, full): Personal Narrator

## Architecture (documented in [governance.md](governance.md))

- **WM-FEAT-0155** (required, core): Minimal Qt and C++ native bridge
- **WM-FEAT-0156** (required, core): Isolated Rust WireCore sidecar
- **WM-FEAT-0157** (required, core): Local authenticated versioned IPC
- **WM-FEAT-0158** (required, core): WireCore crash and hang isolation
- **WM-FEAT-0159** (required, release): Reversible strangler migration for any inherited replacement
- **WM-FEAT-0160** (required, core): No mass rename or broad source reorganization

## Classic Client (documented in [terminal.md](terminal.md))

- **WM-FEAT-0001** (required, full): terminal pane
- **WM-FEAT-0002** (required, full): ANSI/xterm/truecolor support path
- **WM-FEAT-0003** (required, full): scrollback
- **WM-FEAT-0004** (required, full): command history
- **WM-FEAT-0005** (required, full): aliases
- **WM-FEAT-0006** (required, full): triggers
- **WM-FEAT-0007** (required, full): timers
- **WM-FEAT-0008** (required, full): macros/hotkeys
- **WM-FEAT-0009** (required, full): speed-walking
- **WM-FEAT-0010** (required, full): speedwalk throttling
- **WM-FEAT-0011** (required, full): capture/output panes
- **WM-FEAT-0012** (required, full): status bars/gauges
- **WM-FEAT-0013** (required, full): variables/state tables
- **WM-FEAT-0014** (required, full): trigger wizard
- **WM-FEAT-0015** (required, full): command input triggers
- **WM-FEAT-0016** (required, full): gag/highlight/substitute triggers
- **WM-FEAT-0017** (required, full): multi-state triggers
- **WM-FEAT-0018** (required, full): spellcheck/autocorrect
- **WM-FEAT-0019** (required, full): tab/entity/command-template completion
- **WM-FEAT-0020** (required, full): logging/transcripts
- **WM-FEAT-0021** (required, full): layouts, panes, dashboards, themes
- **WM-FEAT-0161** (required, ai): script debugger and variable inspector
- **WM-FEAT-0162** (required, ai): event replay for scripts and triggers
- **WM-FEAT-0163** (required, core): slow trigger and pathological regex quarantine
- **WM-FEAT-0164** (required, core): builder tools

## Command Safety (documented in [security.md](security.md))

- **WM-FEAT-0174** (required, core): per-world command schema and risk tiers
- **WM-FEAT-0175** (required, core): known-safe and known-dangerous command policies
- **WM-FEAT-0176** (required, core): argument validation and deny allow rules
- **WM-FEAT-0177** (required, core): destructive action confirmation
- **WM-FEAT-0178** (required, core): visible AI command queue
- **WM-FEAT-0179** (required, core): audit of suggestion command pacing approval and send result
- **WM-FEAT-0180** (required, core): prompt injection defenses before automated commands

## Context (documented in [ai.md](ai.md))

- **WM-FEAT-0196** (required, ai): typed RoomSeen event
- **WM-FEAT-0197** (required, ai): typed ExitSeen event
- **WM-FEAT-0198** (required, ai): typed MobSeen event
- **WM-FEAT-0199** (required, ai): typed PlayerSeen event
- **WM-FEAT-0200** (required, ai): typed AnimalSeen event
- **WM-FEAT-0201** (required, ai): typed PKerOrPvPerSeen event
- **WM-FEAT-0202** (required, ai): typed CombatStarted and CombatEnded events
- **WM-FEAT-0203** (required, ai): typed ItemSeen and QuestClueSeen events
- **WM-FEAT-0204** (required, ai): typed PromptSeen and HealthChanged events
- **WM-FEAT-0205** (required, ai): typed CommandSucceeded and CommandFailed events
- **WM-FEAT-0206** (required, ai): typed SocialMessageSeen and redacted private message events
- **WM-FEAT-0207** (required, immersion): typed RendererEmitCandidate event

## Governance (documented in [governance.md](governance.md))

- **WM-FEAT-0146** (required, core): Mudlet fork with preserved Git history
- **WM-FEAT-0147** (required, core): Pinned upstream commit and stable release evidence
- **WM-FEAT-0148** (required, core): Upstream synchronization rehearsal and rollback
- **WM-FEAT-0149** (required, core): Patch classification for upstreamable, bridge, feature, branding, and security changes
- **WM-FEAT-0150** (required, core): Source evidence registry for every external symbol and command
- **WM-FEAT-0151** (required, core): Feature coverage gate
- **WM-FEAT-0152** (required, core): Specification requirement trace gate
- **WM-FEAT-0153** (required, core): Expected-file scope fence with evidence-backed brownfield amendments
- **WM-FEAT-0154** (required, core): Append-only ledger, lease, scheduler, green tags, and bounded retries

## Headless, Replay, and Developer (documented in [headless.md](headless.md))

- **WM-FEAT-0121** (required, full): CLI/headless sessions
- **WM-FEAT-0122** (required, full): scenario files
- **WM-FEAT-0123** (required, full): JSONL event output
- **WM-FEAT-0124** (required, full): Headless Supervisor Dashboard
- **WM-FEAT-0125** (required, full): multi-session orchestration rules
- **WM-FEAT-0126** (required, full): Session Replay
- **WM-FEAT-0127** (required, full): AI Debugger
- **WM-FEAT-0128** (required, full): sanitized fixture generator
- **WM-FEAT-0129** (required, full): Compatibility Lab
- **WM-FEAT-0130** (required, full): Protocol Museum fake MUD servers
- **WM-FEAT-0131** (required, full): performance benchmark suite
- **WM-FEAT-0132** (required, full): local diagnostic bundles
- **WM-FEAT-0133** (research, future): future autonomous bug remediation

## Help (documented in [help.md](help.md))

- **WM-FEAT-0213** (required, developer): circular help bubbles beside fields feature cards wizard steps and advanced controls
- **WM-FEAT-0214** (required, developer): help popovers with safe defaults validation hints privacy notes and documentation links
- **WM-FEAT-0215** (required, developer): Ask WireMudder AI handoff
- **WM-FEAT-0216** (required, developer): local-only and remote-redacted help modes
- **WM-FEAT-0217** (required, developer): generated Help Knowledge Index
- **WM-FEAT-0218** (required, developer): optional local source checkout indexing
- **WM-FEAT-0219** (required, developer): coach cannot directly change protected settings or send commands

## Mapper (documented in [mapper.md](mapper.md))

- **WM-FEAT-0165** (required, core): zones and area clustering
- **WM-FEAT-0166** (required, core): custom hidden locked one-way and portal exits
- **WM-FEAT-0167** (required, core): weighted and timed routing
- **WM-FEAT-0168** (required, core): map import export and backups

## Memory (documented in [ai.md](ai.md))

- **WM-FEAT-0191** (required, ai): room identity confidence
- **WM-FEAT-0192** (required, ai): user correction and supersession workflow
- **WM-FEAT-0193** (required, ai): current-room hot cache
- **WM-FEAT-0194** (required, ai): entity observations for NPCs mobs animals players and PvP-visible characters
- **WM-FEAT-0195** (required, ai): World Bible region palettes terrain lighting factions silhouettes architecture and roleplay continuity

## Multi-Session and Routing (documented in [sessions.md](sessions.md))

- **WM-FEAT-0078** (required, full): multiple tabs/windows
- **WM-FEAT-0079** (required, full): Character Memory Profiles
- **WM-FEAT-0080** (required, full): per-character default network routing profile
- **WM-FEAT-0081** (required, full): direct/system-network profile
- **WM-FEAT-0082** (required, full): SOCKS5 profile
- **WM-FEAT-0083** (required, full): HTTP CONNECT profile
- **WM-FEAT-0084** (required, full): SOCKS4a profile
- **WM-FEAT-0085** (required, full): Tor-compatible local SOCKS endpoint profile
- **WM-FEAT-0086** (required, full): SSH dynamic-forward profile
- **WM-FEAT-0087** (required, full): external VPN metadata profiles for WireGuard/OpenVPN/system VPN routes
- **WM-FEAT-0088** (research, future): future interface binding
- **WM-FEAT-0089** (research, future): future VM/container/network namespace profile
- **WM-FEAT-0090** (research, future): future self-hosted relay profile
- **WM-FEAT-0091** (required, full): explicit egress verification
- **WM-FEAT-0092** (required, full): routing audit log

## Operations (documented in [operations.md](operations.md))

- **WM-FEAT-0241** (required, release): secure source and binary release artifacts with checksums SBOM and provenance
- **WM-FEAT-0242** (required, release): Windows macOS and Linux installer and upgrade certification
- **WM-FEAT-0243** (required, core): backup restore rollback and incident runbooks
- **WM-FEAT-0244** (required, release): core release with optional providers visibly disabled until certification

## Performance (documented in [performance.md](performance.md))

- **WM-FEAT-0134** (required, full): P0/P1/P2/P3/P4 priority rings
- **WM-FEAT-0135** (required, full): bounded event bus
- **WM-FEAT-0136** (required, full): terminal frame buffer
- **WM-FEAT-0137** (required, full): batched IPC/UI updates
- **WM-FEAT-0138** (required, full): queue metrics
- **WM-FEAT-0139** (required, full): degradation/fallback per subsystem
- **WM-FEAT-0140** (required, full): idle-only maintenance
- **WM-FEAT-0141** (required, full): slow trigger quarantine
- **WM-FEAT-0142** (required, full): renderer emit dropping/coalescing
- **WM-FEAT-0143** (required, full): voice cancellation and load shedding
- **WM-FEAT-0144** (required, full): AI cancellation and provider fallback
- **WM-FEAT-0145** (required, full): token budget and cost audit

## Power User and Ecosystem (documented in [packages.md](packages.md))

- **WM-FEAT-0104** (required, full): scripting runtime abstraction
- **WM-FEAT-0105** (required, full): future Lua-compatible path
- **WM-FEAT-0106** (required, full): script editor/debugger/variable inspector
- **WM-FEAT-0107** (required, full): Macro Forge
- **WM-FEAT-0108** (required, full): Trigger Test Lab
- **WM-FEAT-0109** (required, full): command palette
- **WM-FEAT-0110** (required, full): profile templates
- **WM-FEAT-0111** (required, full): world onboarding wizard
- **WM-FEAT-0112** (required, full): per-world capability detector
- **WM-FEAT-0113** (required, full): package browser
- **WM-FEAT-0114** (required, full): world packs
- **WM-FEAT-0115** (required, full): command packs
- **WM-FEAT-0116** (required, full): trigger/macro packs
- **WM-FEAT-0117** (required, full): renderer packs
- **WM-FEAT-0118** (required, full): soundscape packs
- **WM-FEAT-0119** (required, full): Soul.md templates
- **WM-FEAT-0120** (research, future): Mudlet/MUSHclient/TinTin/zMUD/CMUD importers/research paths

## Privacy (documented in [privacy.md](privacy.md))

- **WM-FEAT-0220** (required, core): AI context disclosure with provider token count memory IDs and transcript ranges
- **WM-FEAT-0221** (required, developer): user-reviewed diagnostic export
- **WM-FEAT-0222** (required, core): private tells pages and whispers protected by default

## Privacy and Security (documented in [privacy.md](privacy.md))

- **WM-FEAT-0093** (required, full): Privacy Firewall
- **WM-FEAT-0094** (required, full): Local Only Lockdown
- **WM-FEAT-0095** (required, full): Secrets Vault
- **WM-FEAT-0096** (required, full): redaction middleware
- **WM-FEAT-0097** (required, full): immutable audit timeline
- **WM-FEAT-0098** (required, full): plugin/package permission firewall
- **WM-FEAT-0099** (required, full): protected mic/listening state
- **WM-FEAT-0100** (required, full): AI context disclosure
- **WM-FEAT-0101** (required, full): no hidden telemetry
- **WM-FEAT-0102** (required, full): signed updates
- **WM-FEAT-0103** (required, full): signed/provenance-aware packages

## Profiles (documented in [profiles.md](profiles.md))

- **WM-FEAT-0169** (required, core): per-character AI provider and privacy defaults
- **WM-FEAT-0170** (required, core): per-character renderer and soundscape defaults
- **WM-FEAT-0171** (required, core): per-character macro trigger and script packs
- **WM-FEAT-0172** (required, core): per-character Soul document and command database
- **WM-FEAT-0173** (required, core): audit of sensitive default changes

## Protocol (documented in [sessions.md](sessions.md))

- **WM-FEAT-0022** (required, full): Telnet basics
- **WM-FEAT-0023** (required, full): TLS/telnets path
- **WM-FEAT-0024** (required, full): ANSI/xterm/truecolor
- **WM-FEAT-0025** (required, full): MCCP
- **WM-FEAT-0026** (required, full): GMCP
- **WM-FEAT-0027** (required, full): MSDP
- **WM-FEAT-0028** (required, full): MSSP
- **WM-FEAT-0029** (required, full): MXP
- **WM-FEAT-0030** (required, full): MSP
- **WM-FEAT-0031** (required, full): MCP/simpleedit path
- **WM-FEAT-0032** (required, full): NAWS
- **WM-FEAT-0033** (required, full): CHARSET
- **WM-FEAT-0034** (required, full): EOR
- **WM-FEAT-0035** (research, future): Pueblo research
- **WM-FEAT-0036** (research, future): Simutronics/GSL research

## Renderer (documented in [renderer.md](renderer.md))

- **WM-FEAT-0208** (required, immersion): clickable and visible exits when available
- **WM-FEAT-0209** (required, immersion): renderer confidence display
- **WM-FEAT-0210** (required, immersion): renderer provenance tracking

## Renderer and Soundscape (documented in [renderer.md](renderer.md))

- **WM-FEAT-0069** (required, full): original retro tile/sprite/diorama renderer
- **WM-FEAT-0070** (required, full): persistent room backdrops
- **WM-FEAT-0071** (required, full): graphical emits for NPCs, mobs, animals, players, PKers/PvPers, items, spells, combat, movement, doors, weather, ambience, and room events
- **WM-FEAT-0072** (required, full): static/low-power/no-animation modes
- **WM-FEAT-0073** (required, full): text-only fallback
- **WM-FEAT-0074** (required, full): style capsules from World Bible
- **WM-FEAT-0075** (required, full): soundscape studio
- **WM-FEAT-0076** (required, full): room/area/combat/boss/weather/death/victory audio bindings
- **WM-FEAT-0077** (required, full): local/user-owned/signed/licensed assets

## Telemetry (documented in [telemetry.md](telemetry.md))

- **WM-FEAT-0223** (required, developer): crash-safe bounded ring buffers
- **WM-FEAT-0224** (required, developer): structured event fingerprints and correlation IDs
- **WM-FEAT-0225** (required, developer): severity classification for critical error warning info and debug
- **WM-FEAT-0226** (required, developer): performance regression workflow
- **WM-FEAT-0227** (required, developer): diagnostic deduplication without private content
- **WM-FEAT-0228** (required, developer): root-cause routing by subsystem and priority ring
- **WM-FEAT-0229** (required, developer): bounded autonomous patch planning and validation

## Updates (documented in [updates.md](updates.md))

- **WM-FEAT-0230** (required, release): signed core app manifests and artifacts
- **WM-FEAT-0231** (required, release): development canary beta and stable channels
- **WM-FEAT-0232** (required, release): staged rollout and kill switch metadata
- **WM-FEAT-0233** (required, release): interrupted download recovery
- **WM-FEAT-0234** (required, release): failed update startup health and rollback
- **WM-FEAT-0235** (required, release): separate core provider context command plugin renderer audio model and help lanes
- **WM-FEAT-0236** (required, release): permission expansion rejection
- **WM-FEAT-0237** (required, release): migration backup restore and resumability
- **WM-FEAT-0238** (required, release): active-session update deferral
- **WM-FEAT-0239** (required, release): maintainer-controlled emergency patch workflow
- **WM-FEAT-0240** (required, release): Local Only Lockdown blocks remote update and asset checks

## Voice (documented in [voice.md](voice.md))

- **WM-FEAT-0057** (required, full): real-time conversational Voice Companion
- **WM-FEAT-0058** (required, full): push-to-talk and hold-to-talk
- **WM-FEAT-0059** (required, full): optional wake phrase after opt-in
- **WM-FEAT-0060** (required, full): local-first STT/TTS
- **WM-FEAT-0061** (required, full): opt-in remote voice providers
- **WM-FEAT-0062** (required, full): voice macros
- **WM-FEAT-0063** (required, full): spoken room/map/quest/combat/setup summaries
- **WM-FEAT-0064** (required, full): per-character voice profiles
- **WM-FEAT-0065** (required, full): per-agent voice styles for copilot, mapper, quest, safety, narrator, renderer, and help agents
- **WM-FEAT-0066** (required, full): barge-in/cancel
- **WM-FEAT-0067** (required, full): subtitles/transcript controls
- **WM-FEAT-0068** (required, full): accessibility spoken mode
- **WM-FEAT-0211** (required, immersion): spoken help and setup summaries
- **WM-FEAT-0212** (required, immersion): different voice styles for copilot mapper quest safety narrator renderer and help agents
