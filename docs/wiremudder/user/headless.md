# Headless, Replay, and the API

The developer profile adds headless operation, replay, diagnostics, package
tooling, and bug automation (SPEC-000-R06).

## Headless Operation

WireMudder can run without a GUI for automation, testing, and scripting.
Headless mode accepts a world profile, runs it, and emits structured JSONL
events that describe what happened (WM-FEAT-0121).

## Replay

Session replay captures the events of a session so you can replay,
debug, and diagnose what happened (WM-FEAT-0127). Replay is bounded and
local.

## API

Headless and CLI users receive equivalent command and configuration help
(SPEC-018-R07). The API surface is documented in the
[Developer Guide](../developer/README.md).

## Compatibility Lab and Protocol Museum

The developer profile includes a Compatibility Lab and Protocol Museum for
testing protocol behavior (WM-FEAT-0119). These are research and developer
tools; they do not change how the client connects to your world.
