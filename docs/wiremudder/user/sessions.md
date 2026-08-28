# Sessions and Protocols

WireMudder connects to MUD worlds over the standard text protocols. The
protocol layer is preserved from the inherited client and extended with
evidence-based capability detection (WM-FEAT-0154).

## Multiple Sessions

You can run multiple sessions at once, each in its own tab. Multi-play lets
you send the same input to several sessions (WM-FEAT-0156).

## Routing

Routing controls which session receives input from scripts, triggers, or
the AI companion. Routing changes are recorded and require explicit
approval — a package or script cannot silently reroute your input
(WM-FEAT-0168).

## Capability Detection

World onboarding identifies server capabilities through observed
negotiation and user confirmation — never invented assumptions
(SPEC-018-R08). The capability record is local and updated only from
observed evidence.

## Unsupported Protocols

Protocols marked research (Pueblo, Simutronics/GSL, and future VM/relay
profiles) are **not implemented**. They are listed in the feature index
with an honest research label. No claim is made that they work.

## Command Safety

The command-safety layer (SPEC-011) reviews commands that could be
dangerous before they are sent, and gates them behind your approval
(WM-FEAT-0176). The manual command path is preserved.
