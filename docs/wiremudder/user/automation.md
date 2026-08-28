# Automation

Automation turns the terminal into a workflow. WireMudder preserves the Lua
5.1 scripting surface inherited from Mudlet as the primary compatibility
surface (WM-SPEC-008-R01), and adds measured budgets so a slow script
cannot freeze your session (WM-SPEC-008-R02).

## Aliases

Aliases match what you type and replace it before sending. Create them from
the automation toolbar. Each alias can be enabled or disabled, and the
script editor checks your syntax before you save it (WM-SPEC-008-R07).

## Triggers

Triggers match incoming lines and fire Lua code, prompts, or other
responses. Triggers can be plain text or regular expressions, and they can
fire on exact lines or substrings. A runaway hook is quarantined rather
than allowed to terminate the session (WM-SPEC-008-R10).

## Timers

Timers fire code after a delay or on a schedule. Timers run inside the
same measured budget as triggers and scripts.

## Macros and Hotkeys

Macros bind key combinations to commands or scripts. They are stored with
your profile and remain local.

## Script Editor and Debug Tools

The script editor, debug console, variable inspector, event replay,
Macro Forge, and Trigger Test Lab are part of the developer profile
(WM-SPEC-008-R07). Use them to test a trigger against a sample line before
you rely on it in play.

## Budgets and Slow Offenders

Every script, trigger, alias, timer, macro, and key binding runs with a
measured budget. When one exceeds its budget, the client records a
slow-offender diagnostic instead of blocking your input. You can find these
diagnostics in the support bundle (see [Telemetry](telemetry.md)).

## Permissions

Scripts do not get access to your files, network, microphone, secrets, or
AI egress unless the containing package declared that permission and you
approved it. The default is deny (WM-SPEC-008-R04). See
[Packages](packages.md) and the [Package Author Guide](../package-author/README.md).
