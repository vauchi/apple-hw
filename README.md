<!-- SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me> -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# apple-hw

Vauchi's hardware shell for iOS and macOS. It executes the hardware commands
[Vauchi Core](https://gitlab.com/vauchi/core) emits and reports what the
OS observed as events, through CoreBluetooth, Core NFC, AVFoundation and
Network.framework. It decides nothing: Core chooses peers, roles,
framing, deadlines and fallback. It shows no UI: the app's display shell
renders everything the user sees.

It serves the iOS and macOS apps.

## Contents (planned)

- one port per hardware capability: BLE, NFC, camera, audio, direct send
- contract tests against Core's command/event fixtures, run on a fake OS
  backend in CI
- real-device tests, a capability probe, measurement tools and
  diagnostics

## License

GPL-3.0-or-later; see `LICENSE`.
