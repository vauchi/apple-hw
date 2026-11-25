// SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me>
// SPDX-License-Identifier: GPL-3.0-or-later

@testable import AppleHw
import CommandContract
import EventContract
import Foundation
import VauchiContract

final class FakeLocationProvider: LocationProviding {
    var servicesEnabled = true
    var authorization: LocationAuthorization = .authorized
    var onEvent: ((LocationProviderEvent) -> Void)?
    private(set) var authorizationRequests = 0
    private(set) var fixRequests = 0

    func requestAuthorization() {
        authorizationRequests += 1
    }

    func requestFix() {
        fixRequests += 1
    }

    func cancel() {}

    func deliver(_ event: LocationProviderEvent) {
        onEvent?(event)
    }
}

final class ManualClock: HardwareClock {
    private final class Timer: HardwareTimer {
        let milliseconds: Int
        let work: () -> Void
        var cancelled = false

        init(milliseconds: Int, work: @escaping () -> Void) {
            self.milliseconds = milliseconds
            self.work = work
        }

        func cancel() {
            cancelled = true
        }
    }

    private var timers: [Timer] = []

    var pendingDelays: [Int] {
        timers.filter { !$0.cancelled }.map(\.milliseconds)
    }

    func after(milliseconds: Int, _ work: @escaping () -> Void) -> HardwareTimer {
        let timer = Timer(milliseconds: milliseconds, work: work)
        timers.append(timer)
        return timer
    }

    func fireAll() {
        for timer in timers where !timer.cancelled {
            timer.cancelled = true
            timer.work()
        }
    }
}

/// Commands enter as Core sends them: JSON the contract's schema accepts.
func command(_ json: String) throws -> Command {
    try ContractJSON.decodeCommand(Data(json.utf8))
}

/// An event as it leaves for Core, after the contract's schema accepted it.
func wire(_ event: Event) throws -> NSDictionary {
    let data = try ContractJSON.encodeEvent(event)
    _ = try ContractJSON.decodeEvent(data)
    return try JSONSerialization.jsonObject(with: data) as! NSDictionary
}
