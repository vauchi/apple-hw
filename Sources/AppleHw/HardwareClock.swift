// SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me>
// SPDX-License-Identifier: GPL-3.0-or-later

import Dispatch

/// Timeouts go through this, so tests fire them without waiting (CC-06).
protocol HardwareClock {
    func after(milliseconds: Int, _ work: @escaping () -> Void) -> HardwareTimer
}

protocol HardwareTimer {
    func cancel()
}

struct MainQueueClock: HardwareClock {
    private struct WorkItemTimer: HardwareTimer {
        let item: DispatchWorkItem

        func cancel() {
            item.cancel()
        }
    }

    func after(milliseconds: Int, _ work: @escaping () -> Void) -> HardwareTimer {
        let item = DispatchWorkItem(block: work)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds), execute: item)
        return WorkItemTimer(item: item)
    }
}
