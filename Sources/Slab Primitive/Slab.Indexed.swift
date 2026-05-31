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

public import Index_Primitives

extension Slab where Element: ~Copyable {

    /// A phantom-typed wrapper providing `Index<Tag>` instead of `Index<Element>`.
    ///
    /// Zero-cost abstraction using `.retag()` for all index conversions. The
    /// wrapper composes the base ``Slab`` and cannot stand alone, so it is
    /// co-located with the base type module.
    public struct Indexed<Tag: ~Copyable>: ~Copyable {
        @usableFromInline
        package var _base: Slab<Element>

        /// Creates an empty indexed slab.
        @inlinable
        public init() {
            self._base = Slab()
        }

        /// Creates an indexed slab with the specified minimum capacity.
        @inlinable
        public init(minimumCapacity: Index<Tag>.Count) {
            self._base = Slab(minimumCapacity: minimumCapacity.retag(Element.self))
        }
    }
}

// MARK: - Conditional Conformances

extension Slab.Indexed: Sendable where Element: Sendable {}
