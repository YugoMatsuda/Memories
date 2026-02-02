// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Memories",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Memories", targets: ["Memories"]),
    ],
    dependencies: [
        .package(path: "../Utilities"),
        .package(path: "../Domains"),
        .package(path: "../Repositories"),
        .package(path: "../UseCases"),
        .package(path: "../UILogics"),
        .package(path: "../UIComponents"),
    ],
    targets: [
        .target(
            name: "Memories",
            dependencies: [
                "Utilities",
                "Domains",
                "Repositories",
                "UseCases",
                "UILogics",
                "UIComponents",
            ]
        ),
        .testTarget(name: "MemoriesTests", dependencies: ["Memories"]),
    ]
)
