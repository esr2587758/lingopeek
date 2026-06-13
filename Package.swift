// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LingoPeek",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LingoPeek", targets: ["LingoPeekApp"]),
        .executable(name: "LingoPeekAIProbe", targets: ["LingoPeekAIProbe"]),
        .executable(name: "LingoPeekCoreChecks", targets: ["LingoPeekCoreChecks"]),
        .library(name: "LingobarCore", targets: ["LingobarCore"])
    ],
    targets: [
        .target(name: "LingobarCore"),
        .executableTarget(
            name: "LingoPeekApp",
            dependencies: ["LingobarCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("Security"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .executableTarget(
            name: "LingoPeekAIProbe",
            dependencies: ["LingobarCore"]
        ),
        .executableTarget(
            name: "LingoPeekCoreChecks",
            dependencies: ["LingobarCore"]
        )
    ]
)
