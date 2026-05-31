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

extension Slab where Element: ~Copyable {
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
