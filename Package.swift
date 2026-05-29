// swift-tools-version: 6.3.1

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
        .library(
            name: "Slab Primitives Test Support",
            targets: ["Slab Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-finite-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-bit-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-collection-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-sequence-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-slab-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Core
        .target(
            name: "Slab Primitives Core",
            dependencies: [
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Finite Primitives", package: "swift-finite-primitives"),
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Buffer Slab Primitives", package: "swift-buffer-slab-primitives"),
                .product(name: "Buffer Slab Inline Primitives", package: "swift-buffer-slab-primitives"),
            ]
        ),

        // MARK: - Dynamic
        .target(
            name: "Slab Dynamic Primitives",
            dependencies: [
                "Slab Primitives Core",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),

        // MARK: - Static
        .target(
            name: "Slab Static Primitives",
            dependencies: [
                "Slab Primitives Core",
                .product(name: "Buffer Slab Inline Primitives", package: "swift-buffer-slab-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),

        // MARK: - Umbrella
        .target(
            name: "Slab Primitives",
            dependencies: [
                "Slab Primitives Core",
                "Slab Dynamic Primitives",
                "Slab Static Primitives",
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "Slab Primitives Tests",
            dependencies: [
                "Slab Primitives",
                .product(name: "Buffer Primitives Test Support", package: "swift-buffer-primitives"),
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "Slab Primitives Test Support",
            dependencies: [
                "Slab Primitives",
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
                .product(name: "Finite Primitives Test Support", package: "swift-finite-primitives"),
                .product(name: "Bit Primitives Test Support", package: "swift-bit-primitives"),
                .product(name: "Buffer Primitives Test Support", package: "swift-buffer-primitives"),
                .product(name: "Collection Primitives Test Support", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives Test Support", package: "swift-sequence-primitives"),
            ],
            path: "Tests/Support"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
