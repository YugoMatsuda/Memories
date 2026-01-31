// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Domains",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Domains", targets: ["Domains"]),
    ],
    targets: [
        .target(name: "Domains"),
        .testTarget(name: "DomainsTests", dependencies: ["Domains"]),
    ]
)
