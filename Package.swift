// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "tunnel-watch",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "TunnelWatchCore",
            targets: ["TunnelWatchCore"]
        ),
        .executable(
            name: "tunnel-watch",
            targets: ["tunnel-watch"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "TunnelWatchCore"
        ),
        .executableTarget(
            name: "tunnel-watch",
            dependencies: [
                "TunnelWatchCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "TunnelWatchCoreTests",
            dependencies: ["TunnelWatchCore"]
        ),
    ]
)
