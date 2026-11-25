// SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me>
// SPDX-License-Identifier: GPL-3.0-or-later

import CommandContract
import EventContract

/// One location fix per `LocationRequest` (ADR-051, where an exchange
/// happened), answered exactly once: `LocationResult`, `PermissionDenied` or
/// `HardwareUnavailable`, with `"location"` as the transport.
final class LocationService {
    private static let transport = "location"

    private struct Pending {
        let report: (Event) -> Void
        var timeout: HardwareTimer?
    }

    private let provider: LocationProviding
    private let clock: HardwareClock
    private var pending: Pending?

    init(provider: LocationProviding, clock: HardwareClock) {
        self.provider = provider
        self.clock = clock
        provider.onEvent = { [weak self] event in self?.handle(event) }
    }

    /// A request while one is pending replaces it; the earlier one gets no
    /// answer, since Core asked again.
    func start(_ request: LocationRequest, report: @escaping (Event) -> Void) {
        pending?.timeout?.cancel()
        pending = nil

        guard provider.servicesEnabled else {
            report(ContractEvent.hardwareUnavailable(transport: Self.transport))
            return
        }

        pending = Pending(report: report)
        // Bound the wait, or Core keeps its capture pending with no answer.
        pending?.timeout = clock.after(milliseconds: max(0, request.timeoutMS)) { [weak self] in
            self?.finish(ContractEvent.hardwareUnavailable(transport: Self.transport))
        }

        if provider.authorization == .undetermined {
            provider.requestAuthorization()
        }
        proceed()
    }

    private func proceed() {
        switch provider.authorization {
        case .authorized:
            provider.requestFix()
        case .undetermined:
            break
        case .denied, .restricted:
            finish(ContractEvent.permissionDenied(transport: Self.transport))
        case .unknown:
            finish(ContractEvent.hardwareUnavailable(transport: Self.transport))
        }
    }

    private func handle(_ event: LocationProviderEvent) {
        guard pending != nil else { return }
        switch event {
        case .authorizationChanged:
            proceed()
        case let .fix(fix):
            finish(ContractEvent.locationResult(LocationResult(
                // A negative accuracy is CoreLocation's "no valid accuracy".
                accuracyMeters: fix.horizontalAccuracy >= 0 ? fix.horizontalAccuracy : nil,
                latitude: fix.latitude,
                longitude: fix.longitude
            )))
        case .failed:
            finish(ContractEvent.hardwareUnavailable(transport: Self.transport))
        }
    }

    private func finish(_ event: Event) {
        guard let done = pending else { return }
        pending = nil
        done.timeout?.cancel()
        provider.cancel()
        done.report(event)
    }
}
