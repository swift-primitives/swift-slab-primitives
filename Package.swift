// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-slab-primitives",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(name: "Slab Primitive", targets: ["Slab Primitive"]),
        .library(name: "Slab Primitives", targets: ["Slab Primitives"]),

        .library(name: "Slab Inline Primitive", targets: ["Slab Inline Primitive"]),

        .library(name: "Slab Primitives Test Support", targets: ["Slab Primitives Test Support"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-index-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-finite-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-bit-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-collection-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-sequence-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-buffer-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-buffer-slab-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-storage-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-memory-heap-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-memory-allocation-primitives.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Slab Primitive",
            dependencies: [

                .product(name: "Buffer Protocol Primitives", package: "swift-buffer-primitives"),

                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Buffer Slab Primitives", package: "swift-buffer-slab-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(
                    name: "Storage Contiguous Primitives",
                    package: "swift-storage-primitives"
                ),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(
                    name: "Memory Allocator Primitive",
                    package: "swift-memory-allocation-primitives"
                ),
            ]
        ),

        .target(
            name: "Slab Inline Primitive",
            dependencies: [
                "Slab Primitive",
                .product(name: "Buffer Primitive", package: "swift-buffer-primitives"),
                .product(
                    name: "Buffer Slab Inline Primitives",
                    package: "swift-buffer-slab-primitives"
                ),
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Finite Bounded Primitives", package: "swift-finite-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(
                    name: "Storage Contiguous Primitives",
                    package: "swift-storage-primitives"
                ),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(
                    name: "Memory Allocator Primitive",
                    package: "swift-memory-allocation-primitives"
                ),
            ]
        ),

        .target(
            name: "Slab Primitives",
            dependencies: [
                "Slab Primitive",
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Buffer Slab Primitives", package: "swift-buffer-slab-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(
                    name: "Storage Contiguous Primitives",
                    package: "swift-storage-primitives"
                ),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(
                    name: "Memory Allocator Primitive",
                    package: "swift-memory-allocation-primitives"
                ),
            ]
        ),

        .testTarget(
            name: "Slab Primitives Tests",
            dependencies: [
                "Slab Primitives",
                "Slab Inline Primitive",
                .product(
                    name: "Buffer Primitives Test Support",
                    package: "swift-buffer-primitives"
                ),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            ]
        ),

        .target(
            name: "Slab Primitives Test Support",
            dependencies: [
                "Slab Primitives",
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
                .product(
                    name: "Finite Primitives Test Support",
                    package: "swift-finite-primitives"
                ),
                .product(name: "Bit Primitives Test Support", package: "swift-bit-primitives"),
                .product(
                    name: "Buffer Primitives Test Support",
                    package: "swift-buffer-primitives"
                ),
                .product(
                    name: "Collection Primitives Test Support",
                    package: "swift-collection-primitives"
                ),
                .product(
                    name: "Sequence Primitives Test Support",
                    package: "swift-sequence-primitives"
                ),
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
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
