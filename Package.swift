// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DollarApple",
    defaultLocalization: "pt-BR",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.6"),
    ],
    targets: [
        // Foundation-only: model, API client, cache, settings, alerts, store. Portable.
        .target(name: "DollarCore"),

        // SwiftUI views and app wiring shared by both executables.
        .target(
            name: "DollarAppleUI",
            dependencies: ["DollarCore"],
            resources: [.process("Resources")]
        ),

        // Direct distribution (GitHub Releases, Homebrew): self-updates with Sparkle.
        .executableTarget(
            name: "DollarApple",
            dependencies: ["DollarAppleUI", .product(name: "Sparkle", package: "Sparkle")],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),

        // Mac App Store: sandboxed, no updater.
        .executableTarget(name: "DollarAppleStore", dependencies: ["DollarAppleUI"]),

        .testTarget(
            name: "DollarCoreTests",
            dependencies: ["DollarCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
