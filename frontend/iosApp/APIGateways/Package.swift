// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "APIGateways",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "APIGateways", targets: ["APIGateways"]),
    ],
    dependencies: [
        .package(path: "../Domains"),
    ],
    targets: [
        .target(name: "APIGateways", dependencies: ["Domains"]),
        .testTarget(name: "APIGatewaysTests", dependencies: ["APIGateways"]),
    ]
)
