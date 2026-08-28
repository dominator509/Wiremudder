# WireMudder Soul, Agent Council, Skills, and Memory Permissions — Design (EP-018 M3)

## Purpose

Soul documents and Studio (WM-FEAT-0042/0043), specialized agent registry
(R02), Agent Skill Tree (WM-FEAT-0044, R05), role-scoped deny-by-default
memory permissions (R06), and budgeted Agent Council with disagreement
records (WM-FEAT-0045, R07). Owning spec: SPEC-014. Depends on EP-006
(forward) and EP-017 (copilot/soul precedent).

## Architecture

```
wire-soul crate (SoulDocument, SoulStudio, SoulError)
  - persona tone/roleplay/boundaries (WM-FEAT-0042)
  - validate + compiled-prompt preview + sandbox + policy precedence + audit
    (WM-FEAT-0043, R04)

wire-agents crate (AgentRole, MemoryClass, PermissionMatrix, SkillTree,
                  Council, CouncilLog, AgentsError)
  - 11 specialized roles (R02)
  - skill tree with provenance/permissions/evaluation (R05)
  - role-scoped deny-by-default memory permissions (R06)
  - budgeted council with disagreement records (R07)

src/wiremudder/ui/soul/soul_boundary.{h,cpp}  [compiled into client]
  - passive Qt pane: persona, compiled prompt, policy precedence, skills,
    permissions, council rows; all 8 states; no authority grant path

schemas/wiremudder/agents/{skill-tree,memory-permissions,council}-v1.json
```

## Behavior

- Soul cannot override policy (obligation 1): SOUL_IMMUTABLE_POLICY domains
  (security, privacy, routing, package, plugin, updater, update, telemetry,
  signing, command safety, emergency-stop) are guarded per SPEC-014-R03 and
  SPEC-022-R04; only weakening verbs (ignore/bypass/override/disable/weaken/
  violate/circumvent/skip/relax/exempt) trigger rejection, so reinforcing
  behaviors ("never answer security questions") are allowed.
- Prompt injection is rejected structurally (SPEC-022-R04/R09): forbidden
  behaviors that attempt instruction override or authority grant ("ignore
  previous instructions", "grant full access", ...) are denied even when
  they name no policy domain; reinforcing prohibitions ("never ...") stay
  allowed.
- Studio validates + previews + sandbox + audits (obligation 2, R04); audit
  bounded at 200 entries.
- Skills declare provenance, permissions, and evaluation (obligation 3, R05);
  only evaluated skills can be enabled.
- Memory access is role-scoped and denied by default (obligation 4, R06):
  absent grants = Deny; the only built-in grant is TokenBudget read on
  Telemetry.
- Council is budgeted and records disagreement (obligation 5, R07): requires
  policy permission, budget and role bounds enforced, every disagreement
  recorded, deterministic synthesis from votes.
- No agent can grant itself authority (obligation 6): PermissionMatrix has no
  role-relative grant path; the pane's canGrantAuthority() is always false.

## Commands

```
cargo test --manifest-path wirecore/crates/wire-soul/Cargo.toml
cargo test --manifest-path wirecore/crates/wire-agents/Cargo.toml
cargo run --manifest-path wirecore/crates/wire-agents/Cargo.toml --example e2e_soul_agents
sh tests/wiremudder/ep018/integration/*.sh
sh tests/wiremudder/ep018/e2e/001-soul-agents-e2e.sh
cmake . && ninja libmudlet_core.a && ninja mudlet   # client build
```

## Observed Behavior (2026-08-28)

- wire-soul: 8 tests passed; wire-agents: 10 tests passed.
- E2E rust: `E2E soul-agents: ok` (validate, deny-by-default, skill install,
  council with 1 disagreement, denied-without-permission).
- C++ pane harness: `E2E soul pane: ok` (all 8 states, data surfaces, no
  authority path).
- Client build: soul_boundary.cpp compiled into libmudlet_core.a (rc=0);
  full executable links (rc=0).
- Integration: soul pane in mudlet_SRCS; passive; no execute path.

## Rollback

- Revert `src/CMakeLists.txt` additions (`wiremudder/ui/soul/...`), delete
  `src/wiremudder/ui/soul/`, revert `wirecore/crates/wire-soul/`,
  `wirecore/crates/wire-agents/`, revert `schemas/wiremudder/agents/`,
  remove tests and docs. Client build returns to pre-EP-018 state.

## Security / Privacy

- No secret access, no remote egress, no routing control, no signing
  capability. Deny-by-default memory permissions and no self-grant authority
  are structural invariants (SPEC-022-R05 least privilege).
