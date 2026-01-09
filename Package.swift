// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-storage-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Storage Primitives",
            targets: ["Storage Primitives"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-standard-library-extensions"),
        .package(path: "../swift-test-support-primitives"),
    ],
    targets: [
        .target(
            name: "Storage Primitives",
            dependencies: [
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
            ]
        ),
        .testTarget(
            name: "Storage Primitives Tests",
            dependencies: [
                "Storage Primitives",
                .product(name: "Test Support Primitives", package: "swift-test-support-primitives"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
