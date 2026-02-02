// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Domains",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Domains", targets: ["Domains"]),
    ],
    targets: [
        .binaryTarget(
            name: "Shared",
            path: "../../shared/build/XCFrameworks/debug/Shared.xcframework"
        ),
        .target(
            name: "Domains",
            dependencies: ["Shared"]
        ),
        .testTarget(name: "DomainsTests", dependencies: ["Domains"]),
    ]
)
