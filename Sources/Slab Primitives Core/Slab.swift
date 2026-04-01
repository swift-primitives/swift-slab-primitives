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

public import Buffer_Slab_Primitives
public import Buffer_Slab_Inline_Primitives
import Index_Primitives
import Bit_Primitives

// MARK: - Slab

/// A fixed-capacity, heap-backed typed slot storage with bitmap occupancy tracking.
///
/// `Slab` provides O(1) insert and remove at consumer-chosen indices,
/// with O(word) first-vacant scan via bitmap. Elements can be `~Copyable`.
///
/// The consumer-chosen `insert(_:at:)` is the primitive operation.
/// Auto-insert `insert(_:)` is composed from `firstVacant()` + `insert(_:at:)`.
@safe
public struct Slab<Element: ~Copyable>: ~Copyable {
    @usableFromInline
    package var _buffer: Buffer<Element>.Slab.Bounded

    /// Creates an empty slab with no allocation.
    @inlinable
    public init() {
        self._buffer = Buffer<Element>.Slab.Bounded(
            minimumCapacity: .zero
        )
    }

    /// Creates a slab with the specified minimum capacity.
    @inlinable
    public init(minimumCapacity: Index<Element>.Count) {
        self._buffer = Buffer<Element>.Slab.Bounded(
            minimumCapacity: minimumCapacity
        )
    }

    // MARK: - Nested Types (PATTERN-022: must remain in same file)

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
        package var _buffer: Buffer<Element>.Slab.Inline<wordCount>

        /// Creates an empty static slab.
        @inlinable
        public init() {
            self._buffer = Buffer<Element>.Slab.Inline()
        }
    }

    /// A phantom-typed wrapper providing `Index<Tag>` instead of `Index<Element>`.
    ///
    /// Zero-cost abstraction using `.retag()` for all index conversions.
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

// MARK: - Conditional Conformances

// Note: Slab is always ~Copyable because Buffer.Slab.Bounded is unconditionally ~Copyable
// (Bit.Vector in the header is ~Copyable).
extension Slab: @unchecked Sendable where Element: Sendable {}

extension Slab.Static: @unchecked Sendable where Element: Sendable {}

extension Slab.Indexed: @unchecked Sendable where Element: Sendable {}

// NOTE: Drain conformances for Slab.Static and Slab.Indexed cannot be declared
// here or in separate files due to constraint poisoning from Sequence.Drain.Protocol's
// associatedtype Element (implicit Copyable). These conformances are in the Dynamic
// and Static modules respectively, where Element: Copyable is already implied.
