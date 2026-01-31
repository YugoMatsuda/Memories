// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "APIClients",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "APIClients", targets: ["APIClients"]),
    ],
    targets: [
        .target(name: "APIClients"),
        .testTarget(name: "APIClientsTests", dependencies: ["APIClients"]),
    ]
)
