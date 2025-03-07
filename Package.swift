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
        // Add dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "Penguin",
            dependencies: [],
            path: "./Penguin/",
            exclude: [
                "Preview Content/Preview Assets.xcassets",
                "Penguin.entitlements",
                "Assets.xcassets",
            ]
        ),
    ]
)