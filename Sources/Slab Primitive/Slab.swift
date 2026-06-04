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
public import Index_Primitives
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives

/// A fixed-capacity, heap-backed typed slot storage with bitmap occupancy tracking.
///
/// `Slab` provides O(1) insert and remove at consumer-chosen indices,
/// with O(word) first-vacant scan via bitmap. Elements can be `~Copyable`.
///
/// The consumer-chosen `insert(_:at:)` is the primitive operation.
/// Auto-insert `insert(_:)` is composed from `firstVacant()` + `insert(_:at:)`.
///
/// ## Variants
///
/// - ``Slab``: Heap-backed, fixed-capacity slot storage (this type)
/// - ``Slab/Static``: Zero-allocation inline storage with compile-time capacity
/// - ``Slab/Indexed``: Phantom-typed index wrapper over ``Slab``
// WHY: Category D — structural Sendable workaround; the type is
// WHY: structurally value-safe but the compiler cannot synthesize
// WHY: Sendable due to a stored pointer / generic parameter shape.
@safe
public struct Slab<Element: ~Copyable>: ~Copyable {
    @usableFromInline
    package var _buffer: Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Slab.Bounded

    /// Creates an empty slab with no allocation.
    @inlinable
    public init() {
        self._buffer = Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Slab.Bounded(
            minimumCapacity: .zero
        )
    }

    /// Creates a slab with the specified minimum capacity.
    @inlinable
    public init(minimumCapacity: Index<Element>.Count) {
        self._buffer = Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Slab.Bounded(
            minimumCapacity: minimumCapacity
        )
    }
}

// MARK: - Conditional Conformances

// Note: Slab is always ~Copyable because Buffer.Slab.Bounded is unconditionally ~Copyable
// (Bit.Vector in the header is ~Copyable).
extension Slab: @unsafe @unchecked Sendable where Element: Sendable {}
