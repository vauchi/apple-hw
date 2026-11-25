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

## Contents

- `AppleHardware`: takes a contract `Command`, runs it when one of its
  ports takes it and reports through `onEvent`; any other command is
  unsupported and reports nothing
- the location port: one CoreLocation fix per `LocationRequest`
- `contract:replay` in CI: each port runs against a fake OS backend, and
  every command and event passes the contract's schema

It depends on the [contract](https://gitlab.com/vauchi/contract) package
at the tag Core pins, not on Core.

## Planned

- one port per remaining hardware capability: BLE, NFC, camera, audio,
  direct send, notifications and wakeups
- real-device tests, a capability probe, measurement tools and
  diagnostics

## License

GPL-3.0-or-later; see `LICENSE`.
