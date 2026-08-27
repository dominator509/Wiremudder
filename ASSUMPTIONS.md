# Assumptions and Verification

| ID | Assumption | Evidence or Reason | Risk If Wrong | Exact Verification | Blocks |
| --- | --- | --- | --- | --- | --- |
| ASM-001 | The target repository preserves Mudlet history. | User requested not to rebuild from scratch. | Compatibility and licensing strategy fail. | `git merge-base --is-ancestor 77086c295f4adf59197e586e689d19bdde8e1008 HEAD` after checkout. | Yes |
| ASM-002 | The initial desktop remains Qt and C++. | Current upstream instructions and user direction. | A second shell recreates mature UI. | EP-000 reads `docs/ai-instructions.md` and source build files. | Yes |
| ASM-003 | Lua 5.1 remains the inherited scripting surface. | Current upstream instructions. | Package and script compatibility assumptions fail. | EP-000 records interpreter source and version evidence. | Yes |
| ASM-004 | Rust WireCore can run as an isolated local process. | Smallest reversible architecture for new systems. | Sidecar contract must be redesigned. | EP-005 benchmark and crash-isolation proof. | Yes for new AI systems |
| ASM-005 | The observed upstream development commit is `77086c295f4adf59197e586e689d19bdde8e1008`. | Official repository snapshot on 2026-08-14. | Lock is stale or unavailable. | `sh scripts/upstream-lock-check.sh`. | Yes |
| ASM-006 | The observed stable release is `Mudlet-4.22.0`. | Official release snapshot on 2026-08-14. | Release comparison is stale. | EP-000 queries or inspects official release refs. | No |
| ASM-007 | Auto-deploy and automatic stable publication are not authorized. | Safer default and no explicit publishing authorization. | Release packet may stop before publish. | `WIREMUDDER_AUTO_DEPLOY=false` in `.env`. | No |
| ASM-008 | Provider, speech, asset, telemetry, and signing credentials are unavailable initially. | User requested autonomous build without current secrets. | Optional adapters remain disabled. | Node-scoped preflight manifests. | No for core |
| ASM-009 | Windows is a primary developer environment and Windows, macOS, and Linux are release targets. | User environment plus inherited cross-platform product. | Platform graph must be adjusted. | EP-000 and EP-036 platform evidence. | No for initial local development |
| ASM-010 | Every feature in the recovered catalog remains desired unless explicitly rejected. | Current user instruction. | Scope may be larger than the first release. | `.agent/features/FEATURES.tsv` and release profiles. | No |
| ASM-011 | The old Tauri-first choice is not binding. | User wants a non-scratch build and accepted fork-first direction. | Architecture reconciliation would be invalid. | ADR-0001 and ADR-0002. | Yes |
| ASM-012 | Legal and security acceptance remains human authority. | Graphlock and release safety. | Autonomous release may stop at a manual decision. | AGENTS.md STOP conditions. | No |
