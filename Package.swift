// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "RainPaste",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "RainPasteApp", targets: ["RainPasteApp"]),
    ],
    targets: [
        .executableTarget(
            name: "RainPasteApp",
            path: "Sources/RainPasteApp"
        ),
        .testTarget(
            name: "RainPasteAppTests",
            dependencies: ["RainPasteApp"],
            path: "Tests/RainPasteAppTests"
        ),
    ]
)
