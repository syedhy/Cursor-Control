// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CursorControl",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CursorControl", targets: ["CursorControl"])
    ],
    targets: [
        .executableTarget(
            name: "CursorControl",
            path: "Sources/CursorControl",
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "CursorControlTests",
            dependencies: ["CursorControl"]
        )
    ]
)
