// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "UILogics",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "UILogics", targets: ["UILogics"]),
    ],
    dependencies: [
        .package(path: "../Domains"),
        .package(path: "../APIClients"),
        .package(path: "../APIGateways"),
        .package(path: "../Repositories"),
        .package(path: "../UseCases"),
        .package(path: "../Utilities"),
    ],
    targets: [
        .target(name: "UILogics", dependencies: ["Domains", "APIClients", "APIGateways", "Repositories", "UseCases", "Utilities"]),
        .testTarget(name: "UILogicsTests", dependencies: ["UILogics"]),
    ]
)
