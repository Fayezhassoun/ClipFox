// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClipFox",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ClipFoxCore", targets: ["ClipFoxCore"]),
        .executable(name: "ClipFox", targets: ["ClipFoxApp"]),
        .executable(name: "ClipFoxCoreCheck", targets: ["ClipFoxCoreCheck"])
    ],
    targets: [
        .target(name: "ClipFoxCore"),
        .executableTarget(
            name: "ClipFoxApp",
            dependencies: ["ClipFoxCore"]
        ),
        .executableTarget(
            name: "ClipFoxCoreCheck",
            dependencies: ["ClipFoxCore"]
        )
    ]
)
