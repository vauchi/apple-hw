// SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me>
// SPDX-License-Identifier: GPL-3.0-or-later

import CoreLocation

final class CoreLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate {
    var onEvent: ((LocationProviderEvent) -> Void)?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var servicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }

    var authorization: LocationAuthorization {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: .authorized
        case .denied: .denied
        case .restricted: .restricted
        case .notDetermined: .undetermined
        @unknown default: .unknown
        }
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestFix() {
        manager.requestLocation()
    }

    func cancel() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        onEvent?(.authorizationChanged)
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        onEvent?(.fix(LocationFix(
            latitude: last.coordinate.latitude,
            longitude: last.coordinate.longitude,
            horizontalAccuracy: last.horizontalAccuracy
        )))
    }

    func locationManager(_: CLLocationManager, didFailWithError _: Error) {
        onEvent?(.failed)
    }
}
