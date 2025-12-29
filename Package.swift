// swift-tools-version: 6.2

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
    targets: [
        .target(
            name: "TunnelWatchCore"
        ),
        .executableTarget(
            name: "tunnel-watch",
            dependencies: ["TunnelWatchCore"]
        ),
        .testTarget(
            name: "TunnelWatchCoreTests",
            dependencies: ["TunnelWatchCore"]
        ),
    ]
)
