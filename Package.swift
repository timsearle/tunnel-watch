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
        .library(
            name: "TunnelWatchAppleSupport",
            targets: ["TunnelWatchAppleSupport"]
        ),
    ],
    targets: [
        .target(
            name: "TunnelWatchCore"
        ),
        .target(
            name: "TunnelWatchAppleSupport",
            dependencies: ["TunnelWatchCore"]
        ),
        .testTarget(
            name: "TunnelWatchCoreTests",
            dependencies: ["TunnelWatchCore"]
        ),
        .testTarget(
            name: "TunnelWatchAppleSupportTests",
            dependencies: ["TunnelWatchAppleSupport"]
        ),
    ]
)
