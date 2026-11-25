// SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me>
// SPDX-License-Identifier: GPL-3.0-or-later

import CommandContract
import EventContract

/// The Apple hardware shell (ADR-077): it runs the hardware commands Core
/// routes to it and reports what the device observed. It decides nothing and
/// shows no UI. Create and use it on the main thread, where CoreLocation
/// delivers its callbacks.
public final class AppleHardware {
    /// Every observation, in the contract's `Event`, for the app to hand to
    /// Core.
    public var onEvent: ((Event) -> Void)?

    private let location: LocationService

    public convenience init() {
        self.init(location: CoreLocationProvider(), clock: MainQueueClock())
    }

    init(location: LocationProviding, clock: HardwareClock) {
        self.location = LocationService(provider: location, clock: clock)
    }

    /// Runs `command` when one of this shell's ports takes it, and returns
    /// `true`. Any other command is `Unsupported`: it returns `false` and
    /// reports nothing.
    @discardableResult
    public func execute(_ command: Command) -> Bool {
        guard case let .commandClass(variant) = command else { return false }
        if let request = variant.locationRequest {
            location.start(request) { [weak self] event in self?.onEvent?(event) }
            return true
        }
        return false
    }
}
