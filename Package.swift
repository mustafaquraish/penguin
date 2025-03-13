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
        .package(url: "https://github.com/simibac/ConfettiSwiftUI", from: "2.0.0"),  // We embed the code directly
    ],
    targets: [
        .executableTarget(
            name: "Penguin",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
                .product(name: "ConfettiSwiftUI", package: "ConfettiSwiftUI"), // We embed the code directly
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