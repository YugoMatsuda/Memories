// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "UIComponents",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "UIComponents", targets: ["UIComponents"]),
    ],
    dependencies: [
        .package(path: "../Domains"),
        .package(path: "../UILogics"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "UIComponents", dependencies: [
            "Domains",
            "UILogics",
            .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
        ]),
        .testTarget(name: "UIComponentsTests", dependencies: ["UIComponents"]),
    ]
)
