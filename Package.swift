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
        ),
        .library(
            name: "Slab Primitives Core",
            targets: ["Slab Primitives Core"]
        ),
        .library(
            name: "Slab Dynamic Primitives",
            targets: ["Slab Dynamic Primitives"]
        ),
        .library(
            name: "Slab Static Primitives",
            targets: ["Slab Static Primitives"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-standard-library-extensions"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-finite-primitives"),
        .package(path: "../swift-bit-primitives"),
        .package(path: "../swift-ownership-primitives"),
        .package(path: "../swift-property-primitives"),
        .package(path: "../swift-collection-primitives"),
        .package(path: "../swift-sequence-primitives"),
        .package(path: "../swift-buffer-primitives"),
    ],
    targets: [
        .target(
            name: "Slab Primitives Core",
            dependencies: [
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Finite Primitives", package: "swift-finite-primitives"),
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Ownership Primitives", package: "swift-ownership-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Buffer Slab Primitives", package: "swift-buffer-primitives"),
            ]
        ),
        .target(
            name: "Slab Dynamic Primitives",
            dependencies: [
                "Slab Primitives Core",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),
        .target(
            name: "Slab Static Primitives",
            dependencies: [
                "Slab Primitives Core",
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),
        .target(
            name: "Slab Primitives",
            dependencies: [
                "Slab Primitives Core",
                "Slab Dynamic Primitives",
                "Slab Static Primitives",
            ]
        ),
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
