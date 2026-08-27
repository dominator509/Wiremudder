# WireMudder Preflight

## Baseline Covenant

Baseline preflight covers the inherited repository, Graphlock pack, source evidence, toolchain, selected CMake preset, Git state, and local-only configuration needed for EP-000 and EP-001. Optional providers have node-scoped preflight and remain disabled when credentials are absent. A new required core credential or account discovered after baseline preflight is a blueprint defect or BLOCKED condition.

## Required Baseline Items

| Item | Purpose | Verification | Fallback |
| --- | --- | --- | --- |
| Git repository with Mudlet history | Fork-first foundation | `scripts/upstream-lock-check.sh` | None. Blocks. |
| Python 3 | Graph, coverage, trace, and scope validators | `python3 --version` | None. Blocks. |
| POSIX shell, awk, grep, sed | Canonical scripts | `command -v` checks | MSYS2 or WSL on Windows. |
| CMake 3.25.1 or newer | Current upstream preset floor | `cmake --version` | Install supported CMake. |
| Ninja and C++20 compiler | Inherited build | EP-000 build skill verification | Platform setup from upstream skill. |
| Qt6 development environment | Inherited desktop | CMake configure | Platform setup from upstream docs. |
| Rust and Cargo | WireCore nodes | Version recorded before EP-005 | EP-000 may defer until EP-005 but cannot mark bridge ready. |
| Selected CMake preset | Noninteractive build | `cmake --list-presets` | Operator selects an offered preset. |
| Local-only mode | Safe default | `.env` value | Required for baseline. |
| Auto-deploy false | Release safety | `.env` value | Required. |

## Node-Scoped Credentials

The following are optional and absent by default: remote model providers, remote speech providers, external telemetry, package hosting, artifact hosting, and update publication. Their nodes create read-only probes and certification records. Missing values keep the adapter disabled.

Signing keys are never put in `.env`, PREFLIGHT tables, agent prompts, or CI logs.

## Machine Table

PREFLIGHT-TABLE-BEGIN
WIREMUDDER_UPSTREAM_REPO|REQUIRED|scripts/probes/upstream_repo.sh
WIREMUDDER_UPSTREAM_COMMIT|REQUIRED|scripts/probes/upstream_commit.sh
WIREMUDDER_CMAKE_PRESET|REQUIRED|scripts/probes/cmake_preset.sh
WIREMUDDER_AUTO_DEPLOY|REQUIRED|scripts/probes/auto_deploy.sh
WIREMUDDER_RELEASE_PROFILE|REQUIRED|scripts/probes/release_profile.sh
WIREMUDDER_LOCAL_ONLY|REQUIRED|scripts/probes/local_only.sh
OPENAI_API_KEY|OPTIONAL|-
ANTHROPIC_API_KEY|OPTIONAL|-
GOOGLE_AI_API_KEY|OPTIONAL|-
XAI_API_KEY|OPTIONAL|-
VENICE_API_KEY|OPTIONAL|-
DEEPSEEK_API_KEY|OPTIONAL|-
ELEVENLABS_API_KEY|OPTIONAL|-
DEEPGRAM_API_KEY|OPTIONAL|-
AZURE_SPEECH_KEY|OPTIONAL|-
AZURE_SPEECH_REGION|OPTIONAL|-
PREFLIGHT-TABLE-END
