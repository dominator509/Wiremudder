# WireMudder Third-Party Notices

This distribution includes the following third-party components. Each
component is listed with its license and the notice/source obligation
that applies. The full license texts are preserved in the referenced
notice paths inside this repository.

## Components

### mudlet-core
- License: GPL-2.0-or-later
- Source: https://github.com/Mudlet/Mudlet.git
- Notice path: `COPYING`
- Source obligation: yes (source code must be made available)

### 3rdparty/edbee-lib
- License: MIT
- Source: https://github.com/Mudlet/edbee-lib.git
- Notice path: `3rdparty/edbee-lib/LICENSE`
- Source obligation: no

### 3rdparty/lcf
- License: MIT
- Source: https://github.com/martin-eden/lua_code_formatter.git
- Notice path: `3rdparty/lcf/LICENSE`
- Source obligation: no

### 3rdparty/qt-tags-widget
- License: MIT
- Source: https://github.com/julian-go/qt-tags-widget.git
- Notice path: `3rdparty/qt-tags-widget/LICENSE`
- Source obligation: no

### 3rdparty/qtkeychain
- License: BSD-3-Clause
- Source: https://github.com/frankosterfeld/qtkeychain.git
- Notice path: `3rdparty/qtkeychain/COPYING`
- Source obligation: no

### 3rdparty/sentry-native
- License: MIT
- Source: https://github.com/getsentry/sentry-native.git
- Notice path: `3rdparty/sentry-native/LICENSE`
- Source obligation: no

### wirecore crates (wire-secrets, wire-policy, wire-privacy, wire-routing, wire-packages, wire-contracts)
- License: GPL-3.0-or-later
- Source: `wirecore/crates/`
- Notice path: `COPYING`
- Source obligation: yes (source code must be made available)

## Verification

The component list, licenses, and notice paths above are generated from
`sbom/wiremudder/inventory.json` and enforced by the
`wiremudder-security` CLI (`sbom` subcommand), which reproduces the
document hash recorded in `sbom/wiremudder/sbom.json` and refuses to
pass when any component fails `license_gate_passes()`.
