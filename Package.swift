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

        // MARK: - Inline variant ([DS-027].1: own product, NOT umbrella-re-exported —
        // the W3 un-park of the parked `Slab.Static`, re-homed as `Slab<E>.Inline<n>`.
        // Units: Inline<n> = ELEMENT/slot count.)
        .library(name: "Slab Inline Primitive", targets: ["Slab Inline Primitive"]),

        // MARK: - Test Support
        .library(name: "Slab Primitives Test Support", targets: ["Slab Primitives Test Support"]),
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

        // MARK: - Inline variant (the un-parked `Slab<E>.Inline<n>`: alias + inline-column
        // op-pin set over the existing `Buffer.Slab.Inline` column). [DS-027].1: own lean
        // target, NOT umbrella-re-exported — the Store.Inline leaf dep lands HERE only.
        .target(
            name: "Slab Inline Primitive",
            dependencies: [
                "Slab Primitive",
                .product(name: "Buffer Primitive", package: "swift-buffer-primitives"),
                .product(name: "Buffer Slab Inline Primitives", package: "swift-buffer-slab-primitives"),
                .product(name: "Bit Primitives", package: "swift-bit-primitives"),
                .product(name: "Finite Bounded Primitives", package: "swift-finite-primitives"),
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
                "Slab Inline Primitive",
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
