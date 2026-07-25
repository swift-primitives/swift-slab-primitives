# Slab Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Slab storage primitives for Swift — a sparse, stable-index slot store parameterized over an explicit storage column, so a handle stays valid across insertions and removals. Foundation-free and Embedded-compatible.

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-slab-primitives.git", branch: "main")
]
```

Add the product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Slab Primitives", package: "swift-slab-primitives")
    ]
)
```

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
