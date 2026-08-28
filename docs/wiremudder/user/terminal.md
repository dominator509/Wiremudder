# Terminal

The terminal pane is the heart of the client. It shows the MUD world as
text, accepts your commands, and preserves the classic Mudlet behavior you
expect (WM-FEAT-0001).

## Colors and Rendering

- ANSI and xterm colors are supported, including truecolor when the
  terminal and server support it (WM-FEAT-0002).
- The scrollback keeps your history and is searchable (WM-FEAT-0003).
- Command history lets you recall previous input lines (WM-FEAT-0004).

## Input

- Type a command in the input line and press Enter to send it.
- The manual command path is preserved and never bypassed by optional
  systems. Nothing you type is intercepted unless you configured an alias,
  trigger, or macro to do so.

## Fonts and Layout

- Choose your font, size, and text scaling from the preferences.
- The terminal supports word wrap, line wrapping, and automatic width
  adjustment to match the world (WM-FEAT-0012).

## What the Terminal Does Not Do

- It does not send your input to any server other than the world you are
  connected to.
- It does not upload your scrollback anywhere. Data stays local
  (SPEC-000-R09).
