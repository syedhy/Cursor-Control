// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VimClick",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "VimClick", targets: ["VimClick"])
    ],
    targets: [
        .executableTarget(
            name: "VimClick",
            path: "Sources/VimClick"
        ),
        .testTarget(
            name: "VimClickTests",
            dependencies: ["VimClick"]
        )
    ]
)
