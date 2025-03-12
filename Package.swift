// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Penguin",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        .executable(name: "Penguin", targets: ["Penguin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.0.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Penguin",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
            ],
            path: "./Penguin/",
            exclude: [
                "Preview Content/Preview Assets.xcassets",
                "Penguin.entitlements",
                "Assets.xcassets",
            ]
        ),
    ]
)