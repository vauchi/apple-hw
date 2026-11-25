// SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me>
// SPDX-License-Identifier: GPL-3.0-or-later

/// The part of CoreLocation the location port uses, so its tests run
/// against a fake (ADR-077 D-7).
protocol LocationProviding: AnyObject {
    var servicesEnabled: Bool { get }
    var authorization: LocationAuthorization { get }
    var onEvent: ((LocationProviderEvent) -> Void)? { get set }

    func requestAuthorization()
    func requestFix()
    func cancel()
}

enum LocationAuthorization: Equatable {
    case authorized
    case denied
    case restricted
    case undetermined
    case unknown
}

struct LocationFix: Equatable {
    let latitude: Double
    let longitude: Double
    /// Negative when CoreLocation has no valid accuracy for the fix.
    let horizontalAccuracy: Double
}

enum LocationProviderEvent: Equatable {
    case authorizationChanged
    case fix(LocationFix)
    case failed
}
