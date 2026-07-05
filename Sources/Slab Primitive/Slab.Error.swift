// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// The error surface is PRESERVED across the W2 hoist (minimal-drift structural
// reshape). The tower-wide remove-from-empty Optional convention (adt-tower.md:1491)
// and the M5 `pop()` naming decree ([API-NAME-008]) govern ARGUMENTLESS single-word
// remove-from-empty ops (`pop()`/`dequeue()`); Slab has none — its removes are
// index-ADDRESSED (`remove(at:)`), so neither rule reaches them and the faithful
// hoist keeps the shape-E typed-throws surface. Homed on the carrier `__Slab` so it
// resolves through the front-door alias as `Slab<E>.Error`.
extension __Slab where S: ~Copyable {
    /// Errors that can occur during slab operations.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The slab is full — no vacant slot exists.
        case full

        /// The slot is not occupied.
        case vacant

        /// The slot is already occupied.
        case occupied
    }
}
