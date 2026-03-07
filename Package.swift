// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AWSProfileWidget",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AWSProfileWidget",
            targets: ["AWSProfileWidget"]),
    ],
    dependencies: [
        // SwiftCheck will be added when implementing property-based tests
        // .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "AWSProfileWidget",
            dependencies: []),
        .testTarget(
            name: "AWSProfileWidgetTests",
            dependencies: [
                "AWSProfileWidget",
                // "SwiftCheck"
            ]),
    ]
)
