// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-slab-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Slab Primitives",
            targets: ["Slab Primitives"]
        )
    ],
    dependencies: [
        .package(path: "../swift-standard-library-extensions"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-bit-primitives"),
        .package(path: "../swift-ownership-primitives"),
        .package(path: "../swift-collection-primitives"),
    ],
    targets: [
        .target(
            name: "Slab Primitives",
            dependencies: [
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Ownership Primitives", package: "swift-ownership-primitives"),
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .strictMemorySafety()
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
