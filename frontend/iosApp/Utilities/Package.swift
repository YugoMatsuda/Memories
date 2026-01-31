// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Utilities", targets: ["Utilities"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(name: "Utilities", dependencies: ["KeychainAccess"]),
        .testTarget(name: "UtilitiesTests", dependencies: ["Utilities"]),
    ]
)
