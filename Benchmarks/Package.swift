// swift-tools-version: 6.3.3

import PackageDescription

// Nested benchmark package (io-bench shape, [BENCH-001] primitives row).
// NOT a test package: benchmarks are executable targets run via
// `swift run -c release` — never `swift test` (arc-bench discipline; the
// io-bench hang precedent). Measurement is release-only by invocation.
//
// Authored as part of the ADT-tower W2 slab dispatch (§9.5 gate item: "Benchmarks/
// packages for heap and slab are AUTHORED as part of their W2 dispatches"). The
// harness is the baselines-doc microprobe methodology (Bench.swift / Bench.Result.swift
// are the array family's generic core, copied verbatim from the heap dispatch). Slab
// has NO family baseline rows yet — these are the FIRST rows of record. 6.3.3 label of
// record: "Apple Swift 6.3.3 (swiftlang-6.3.3.1.3), XcodeDefault (Xcode 26.6 17F113)".
//
// WORKTREE-IDENTITY GOTCHA (§6): `.package(path: "../")` resolves identity to the
// on-disk basename. In the merged tree that is `swift-slab-primitives` (committed
// below, correct). To RUN inside the worktree (basename `adt-tower-w2`), transiently
// sed the product `package:` ref to `adt-tower-w2`, run, then restore.
let package = Package(
    name: "slab-bench",
    platforms: [
        .macOS(.v26),
    ],
    dependencies: [
        .package(path: "../"),
    ],
    targets: [
        .executableTarget(
            name: "Slab Benchmarks",
            dependencies: [
                .product(name: "Slab Primitives", package: "swift-slab-primitives"),
            ],
            path: "Slab Benchmarks"
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
