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

public import Slab_Primitive
public import Buffer_Slab_Inline_Primitives

extension Slab where Element: ~Copyable {

    // MARK: - Static (Fixed-Capacity, Inline Storage)

    /// A fixed-capacity, inline (stack-allocated) slab.
    ///
    /// The `wordCount` parameter determines the capacity in units of
    /// the inline storage's word size.
    ///
    /// Element cleanup is handled by `Storage.Inline`'s deinit, which
    /// iterates its bitvector and deinitializes all tracked elements.
    /// No workarounds needed at this layer.
    public struct Static<let wordCount: Int>: ~Copyable {
        @usableFromInline
        package var _buffer: Buffer<Storage<Element>.Heap>.Slab.Inline<wordCount>

        /// Creates an empty static slab.
        @inlinable
        public init() {
            self._buffer = Buffer<Storage<Element>.Heap>.Slab.Inline()
        }
    }
}

// MARK: - Conditional Conformances

extension Slab.Static: @unsafe @unchecked Sendable where Element: Sendable {}
