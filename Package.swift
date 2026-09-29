// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KHQR",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "KHQR", targets: ["KHQR"]),
    ],
    targets: [
        .target(name: "KHQR"),
        .testTarget(
            name: "KHQRTests",
            dependencies: ["KHQR"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
