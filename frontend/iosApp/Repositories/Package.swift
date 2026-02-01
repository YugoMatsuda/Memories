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
        .package(url: "https://github.com/ashleymills/Reachability.swift", from: "5.0.0"),
    ],
    targets: [
        .target(name: "Repositories", dependencies: [
            "Domains",
            "Utilities",
            .product(name: "Reachability", package: "Reachability.swift"),
        ]),
        .testTarget(name: "RepositoriesTests", dependencies: ["Repositories"]),
    ]
)
