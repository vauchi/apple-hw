// SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me>
// SPDX-License-Identifier: GPL-3.0-or-later

@testable import AppleHw
import EventContract
import Foundation
import XCTest

final class LocationRequestTests: XCTestCase {
    private var location: FakeLocationProvider!
    private var clock: ManualClock!
    private var hardware: AppleHardware!
    private var reported: [Event] = []

    override func setUp() {
        location = FakeLocationProvider()
        clock = ManualClock()
        hardware = AppleHardware(location: location, clock: clock)
        reported = []
        hardware.onEvent = { [unowned self] in reported.append($0) }
    }

    private func requestLocation(timeoutMs: Int = 5000) throws -> Bool {
        try hardware.execute(command(#"{"LocationRequest":{"timeout_ms":\#(timeoutMs)}}"#))
    }

    private func reportedWire() throws -> [NSDictionary] {
        try reported.map(wire)
    }

    func test_a_fix_answers_the_request_once_with_its_coordinates() throws {
        XCTAssertTrue(try requestLocation())

        location.deliver(.fix(LocationFix(latitude: 46.948, longitude: 7.447, horizontalAccuracy: 65)))
        location.deliver(.fix(LocationFix(latitude: 1, longitude: 2, horizontalAccuracy: 3)))
        clock.fireAll()

        XCTAssertEqual(try reportedWire(), [
            ["LocationResult": ["latitude": 46.948, "longitude": 7.447, "accuracy_meters": 65.0]],
        ])
    }

    func test_a_fix_with_an_invalid_accuracy_reports_no_accuracy() throws {
        XCTAssertTrue(try requestLocation())

        location.deliver(.fix(LocationFix(latitude: 46.948, longitude: 7.447, horizontalAccuracy: -1)))

        XCTAssertEqual(try reportedWire(), [
            ["LocationResult": ["latitude": 46.948, "longitude": 7.447]],
        ])
    }

    func test_denied_or_restricted_permission_reports_permission_denied() throws {
        for authorization in [LocationAuthorization.denied, .restricted] {
            setUp()
            location.authorization = authorization

            XCTAssertTrue(try requestLocation())

            XCTAssertEqual(try reportedWire(), [["PermissionDenied": ["transport": "location"]]], "\(authorization)")
            XCTAssertEqual(location.fixRequests, 0, "\(authorization)")
        }
    }

    func test_location_services_off_report_unavailable_without_asking_the_person() throws {
        location.servicesEnabled = false

        XCTAssertTrue(try requestLocation())

        XCTAssertEqual(try reportedWire(), [["HardwareUnavailable": ["transport": "location"]]])
        XCTAssertEqual(location.authorizationRequests, 0)
        XCTAssertEqual(location.fixRequests, 0)
    }

    func test_an_undecided_permission_waits_for_the_answer_then_takes_a_fix() throws {
        location.authorization = .undetermined

        XCTAssertTrue(try requestLocation())
        XCTAssertEqual(location.authorizationRequests, 1)
        XCTAssertEqual(location.fixRequests, 0)
        XCTAssertTrue(reported.isEmpty)

        location.authorization = .authorized
        location.deliver(.authorizationChanged)
        location.deliver(.fix(LocationFix(latitude: 46.948, longitude: 7.447, horizontalAccuracy: 10)))

        XCTAssertEqual(location.fixRequests, 1)
        XCTAssertEqual(try reportedWire(), [
            ["LocationResult": ["latitude": 46.948, "longitude": 7.447, "accuracy_meters": 10.0]],
        ])
    }

    func test_no_fix_within_the_timeout_reports_unavailable_and_a_late_fix_nothing() throws {
        XCTAssertTrue(try requestLocation(timeoutMs: 3000))
        XCTAssertEqual(clock.pendingDelays, [3000])

        clock.fireAll()
        location.deliver(.fix(LocationFix(latitude: 46.948, longitude: 7.447, horizontalAccuracy: 10)))

        XCTAssertEqual(try reportedWire(), [["HardwareUnavailable": ["transport": "location"]]])
    }

    func test_a_fix_cancels_the_timeout() throws {
        XCTAssertTrue(try requestLocation(timeoutMs: 3000))

        location.deliver(.fix(LocationFix(latitude: 46.948, longitude: 7.447, horizontalAccuracy: 10)))

        XCTAssertEqual(clock.pendingDelays, [])
    }

    func test_a_provider_failure_reports_unavailable() throws {
        XCTAssertTrue(try requestLocation())

        location.deliver(.failed)

        XCTAssertEqual(try reportedWire(), [["HardwareUnavailable": ["transport": "location"]]])
    }

    func test_a_command_without_a_port_here_is_unsupported_and_reports_nothing() throws {
        let disconnect = #"{"BleDisconnect":{"device_id":"opaque.peer","direction":"Outbound"}}"#
        let handled = try hardware.execute(command(disconnect))

        XCTAssertFalse(handled)
        XCTAssertTrue(reported.isEmpty)
    }
}
