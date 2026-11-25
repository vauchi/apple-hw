// SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me>
// SPDX-License-Identifier: GPL-3.0-or-later

import EventContract
import Foundation

/// Builds one `Event` variant. The generated `EventClass` initialiser takes
/// every variant as a parameter, so a call to it would break on each
/// contract release that adds one; decoding the variant's own JSON does not.
enum ContractEvent {
    static func locationResult(_ result: LocationResult) -> Event {
        make("LocationResult", result)
    }

    static func permissionDenied(transport: String) -> Event {
        make("PermissionDenied", PermissionDenied(transport: transport))
    }

    static func hardwareUnavailable(transport: String) -> Event {
        make("HardwareUnavailable", HardwareUnavailable(transport: transport))
    }

    private static func make(_ variant: String, _ payload: some Encodable) -> Event {
        do {
            let data = try JSONEncoder().encode([variant: AnyEncodable(payload)])
            return try JSONDecoder().decode(Event.self, from: data)
        } catch {
            // INVARIANT: a generated payload always decodes as its own variant;
            // a failure here is a contract-generator bug, not device input.
            preconditionFailure("contract variant \(variant) did not decode as an Event: \(error)")
        }
    }
}

private struct AnyEncodable: Encodable {
    let value: any Encodable

    init(_ value: some Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
