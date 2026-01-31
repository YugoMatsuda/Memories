// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Repositories",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Repositories", targets: ["Repositories"]),
    ],
    dependencies: [
        .package(path: "../Domains"),
        .package(path: "../Utilities"),
    ],
    targets: [
        .target(name: "Repositories", dependencies: ["Domains", "Utilities"]),
        .testTarget(name: "RepositoriesTests", dependencies: ["Repositories"]),
    ]
)
