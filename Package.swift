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
        .executable(name: "LingoPeekGrammarUIChecks", targets: ["LingoPeekGrammarUIChecks"]),
        .executable(name: "LingoPeekCoreChecks", targets: ["LingoPeekCoreChecks"]),
        .library(name: "LingobarUI", targets: ["LingobarUI"]),
        .library(name: "LingobarCore", targets: ["LingobarCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.4")
    ],
    targets: [
        .target(name: "LingobarCore"),
        .executableTarget(
            name: "LingoPeekApp",
            dependencies: [
                "LingobarCore",
                "LingobarUI",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("Security"),
                .linkedFramework("SwiftUI"),
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        ),
        .executableTarget(
            name: "LingoPeekAIProbe",
            dependencies: ["LingobarCore"]
        ),
        .executableTarget(
            name: "LingoPeekCoreChecks",
            dependencies: ["LingobarCore"]
        ),
        .target(
            name: "LingobarUI",
            dependencies: ["LingobarCore"]
        ),
        .executableTarget(
            name: "LingoPeekGrammarUIChecks",
            dependencies: [
                "LingobarCore",
                "LingobarUI"
            ]
        )
    ]
)
