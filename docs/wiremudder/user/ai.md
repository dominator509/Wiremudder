# AI and Memory

The AI Companion profile adds local-first memory, context distillation,
provider routing, copilot, explanation, and guarded action capabilities
(SPEC-000-R04). These systems never enter the manual gameplay path — you
can play entirely without them.

## Local-First Memory

Memory is stored locally by default. World facts, derived facts, and
session context are kept on your machine. Nothing is uploaded unless you
configure an external provider and grant the relevant permission.

## Context

The context system distills your recent play into bounded capsules that the
AI companion can use to answer questions (WM-FEAT-0101). Context is local,
bounded, and privacy-aware.

## Provider Routing

AI requests route through providers you configure. Routing decisions are
recorded and auditable (WM-FEAT-0183). No provider is used without your
configuration; optional providers stay visibly disabled until certified
(SPEC-000-R07).

## Copilot and Explanations

The copilot suggests actions and explains game concepts. Every action it
proposes is guarded: it cannot send commands or change settings without
your explicit approval (WM-FEAT-0182, SPEC-018-R06).

## Soul Documents

Soul documents define agent personas and permissions. They are local files
with a memory-permissions schema. The AI can only act within the
permissions the Soul document declares and you approved.

## What the AI Cannot Do

- It cannot access secrets.
- It cannot change routing without approval.
- It cannot install packages or send commands on its own.
- It cannot expand its own permissions.
