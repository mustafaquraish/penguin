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
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1"),
    ],
    targets: [
        .executableTarget(
            name: "Penguin",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
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