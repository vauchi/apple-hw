// swift-tools-version: 5.9
// SPDX-FileCopyrightText: 2026 Mattia Egloff <mattia.egloff@pm.me>
// SPDX-License-Identifier: GPL-3.0-or-later

import PackageDescription

let package = Package(
    name: "AppleHw",
    platforms: [.iOS(.v15), .macOS(.v14)],
    products: [.library(name: "AppleHw", targets: ["AppleHw"])],
    dependencies: [
        // Exact, and the same tag Core pins: one contract per app (ADR-078
        // decision 6).
        .package(url: "https://gitlab.com/vauchi/contract.git", exact: "0.101.0"),
    ],
    targets: [
        .target(
            name: "AppleHw",
            dependencies: [
                .product(name: "CommandContract", package: "contract"),
                .product(name: "EventContract", package: "contract"),
            ]
        ),
        .testTarget(
            name: "AppleHwTests",
            dependencies: [
                "AppleHw",
                .product(name: "VauchiContract", package: "contract"),
            ]
        ),
    ]
)
