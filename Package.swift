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
        // MARK: - Base (ADT-tower W2 shape: carrier `__Slab<S>` + front door `Slab<E>`)
        .library(name: "Slab Primitive", targets: ["Slab Primitive"]),
        .library(name: "Slab Primitives", targets: ["Slab Primitives"]),

        // MARK: - Test Support
        .library(name: "Slab Primitives Test Support", targets: ["Slab Primitives Test Support"]),

        // NOTE (ADT-tower W2, 2026-07-05): the `Slab.Static` inline variant targets are
        // PARKED under "Experiments/Slab Static (parked)/" (retained in-tree, out of the
        // build graph — see that directory's README.md). It re-homes at W3 as the
        // `Slab<E>.Inline<n>` front door (§9.3 W3 row, adt-tower.md:1376).
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-finite-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-bit-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-collection-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-sequence-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-slab-primitives.git", branch: "main"),
        // E2 (storage-small-substrate.md): verbose truth form Storage<E>.Contiguous<Memory.Heap<E>>
        // needs direct deps (MemberImportVisibility) on the declaring modules.
        .package(url: "https://github.com/swift-primitives/swift-storage-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-heap-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-allocation-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Carrier + front door (the ADT-tower W2 core: `__Slab<S>` + `Slab<E>` + Slab.Error)
        .target(
            name: "Slab Primitive",
            dependencies: [
                // Seam (D3): the generic observability surface the seam-generic ops ride.
                .product(name: "Buffer Protocol Primitives", package: "swift-buffer-primitives"),
                // Column vocabulary: the default Slab-buffer / heap column.
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Buffer Slab Primitives", package: "swift-buffer-slab-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Memory Allocator Primitive", package: "swift-memory-allocation-primitives"),
            ]
        ),

        // MARK: - Umbrella ([MOD-005]): carrier module + the `peek` non-destructive read.
        .target(
            name: "Slab Primitives",
            dependencies: [
                "Slab Primitive",
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Buffer Slab Primitives", package: "swift-buffer-slab-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Memory Allocator Primitive", package: "swift-memory-allocation-primitives"),
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "Slab Primitives Tests",
            dependencies: [
                "Slab Primitives",
                .product(name: "Buffer Primitives Test Support", package: "swift-buffer-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
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
