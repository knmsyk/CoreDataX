// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "CoreDataX",
    platforms: [
        .macOS(.v12), .iOS(.v15), .tvOS(.v15), .watchOS(.v8)
    ],
    products: [
        .library(
            name: "CoreDataX",
            targets: ["CoreDataX"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CoreDataX",
            dependencies: []),
        .testTarget(
            name: "CoreDataXTests",
            dependencies: ["CoreDataX"]),
    ]
)
