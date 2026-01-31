// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "UseCases",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "UseCases", targets: ["UseCases"]),
    ],
    dependencies: [
        .package(path: "../Domains"),
        .package(path: "../Repositories"),
        .package(path: "../APIGateways"),
        .package(path: "../Utilities"),
    ],
    targets: [
        .target(name: "UseCases", dependencies: ["Domains", "Repositories", "APIGateways", "Utilities"]),
        .testTarget(name: "UseCasesTests", dependencies: ["UseCases"]),
    ]
)
