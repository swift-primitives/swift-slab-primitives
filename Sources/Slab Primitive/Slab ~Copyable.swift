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

import Bit_Primitives
public import Buffer_Protocol_Primitives
public import Buffer_Slab_Primitives
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives

// ============================================================================
// MARK: - Seam-generic observability (rides `Buffer.Protocol`)
// ============================================================================
//
// The Slab column conforms `Buffer.Protocol` ONLY (it is a Buffer-tier discipline,
// not a `Store.Protocol` storage column — unlike Heap's linear column, which
// conforms both). So the seam-generic surface is exactly `Buffer.Protocol`'s
// `count`/`isEmpty`; the sparse bitmap surface is column-pinned below ([DS-029]).

extension __Slab where S: ~Copyable, S: Buffer.`Protocol` {
    /// The number of currently occupied slots (the seam-generic count witness).
    @inlinable
    public var count: Index<S.Element>.Count { column.count }

    /// The number of currently occupied slots (the slab-native vocabulary; equal to
    /// ``count`` — a slab's native ledger IS its occupancy).
    @inlinable
    public var occupancy: Index<S.Element>.Count { column.count }

    /// Whether no slots are occupied.
    @inlinable
    public var isEmpty: Bool { column.isEmpty }
}

// ============================================================================
// MARK: - Construction (column-pinned; heap growth pin KEPT at W2, re-points at W3)
// ============================================================================

extension __Slab where S: ~Copyable {
    /// Creates an empty slab with no allocation.
    @inlinable
    public init<E: ~Copyable>()
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        self.init(
            column: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded(
                minimumCapacity: .zero
            )
        )
    }

    /// Creates a slab with the specified minimum capacity.
    @inlinable
    public init<E: ~Copyable>(minimumCapacity: Index<E>.Count)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        self.init(
            column: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded(
                minimumCapacity: minimumCapacity
            )
        )
    }
}

// ============================================================================
// MARK: - Occupancy queries (column-pinned; the sparse bitmap surface)
// ============================================================================

extension __Slab where S: ~Copyable {
    /// Whether all slots are occupied.
    ///
    /// A column-pinned METHOD, not a property: fullness needs the column's capacity,
    /// which is not on the `Buffer.Protocol` seam (the Slab column is Buffer-tier), so
    /// it cannot ride the seam as a computed property ([DS-029] column-pinned form).
    @inlinable
    public func isFull<E: ~Copyable>() -> Bool
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.isFull
    }

    /// Whether the slot at the given index is occupied.
    @inlinable
    public func isOccupied<E: ~Copyable>(at index: Index<E>) -> Bool
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.isOccupied(at: index.retag(Bit.self))
    }

    /// Returns the first vacant (unoccupied) slot index, or `nil` if full.
    @inlinable
    public func firstVacant<E: ~Copyable>() -> Index<E>?
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.firstVacant()?.retag(E.self)
    }
}

// ============================================================================
// MARK: - Primitive operations (consumer-chosen; column-pinned)
// ============================================================================

extension __Slab where S: ~Copyable {
    /// Inserts an element at the specified slot index.
    ///
    /// - Parameters:
    ///   - element: The element to store.
    ///   - index: The slot index. Must be vacant.
    /// - Throws: `Slab.Error.occupied` if the slot is already occupied.
    @inlinable
    public mutating func insert<E: ~Copyable>(
        _ element: consuming E,
        at index: Index<E>
    ) throws(Error)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        let slot = index.retag(Bit.self)
        guard !column.isOccupied(at: slot) else {
            throw .occupied
        }
        column.insert(consume element, at: slot)
    }

    /// Inserts an element at the specified slot index without occupancy checking.
    @inlinable
    public mutating func insert<E: ~Copyable>(
        _ element: consuming E,
        __unchecked index: Index<E>
    ) where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.insert(consume element, at: index.retag(Bit.self))
    }

    /// Removes and returns the element at the specified slot index.
    ///
    /// - Parameter index: The slot index. Must be occupied.
    /// - Returns: The element that was stored at the index.
    /// - Throws: `Slab.Error.vacant` if the slot is not occupied.
    @inlinable
    public mutating func remove<E: ~Copyable>(
        at index: Index<E>
    ) throws(Error) -> E
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else {
            throw .vacant
        }
        return column.remove(at: slot)
    }

    /// Removes and returns the element at the specified slot index without occupancy checking.
    @inlinable
    public mutating func remove<E: ~Copyable>(
        __unchecked index: Index<E>
    ) -> E where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.remove(at: index.retag(Bit.self))
    }
}

// ============================================================================
// MARK: - Composed operations (column-pinned)
// ============================================================================

extension __Slab where S: ~Copyable {
    /// Inserts an element at the first vacant slot and returns the slot index.
    ///
    /// Composed from `firstVacant()` + `insert(_:at:)`.
    ///
    /// - Parameter element: The element to store.
    /// - Returns: The slot index where the element was stored.
    /// - Throws: `Slab.Error.full` if no vacant slot exists.
    @discardableResult
    @inlinable
    public mutating func insert<E: ~Copyable>(
        _ element: consuming E
    ) throws(Error) -> Index<E>
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        guard let slot: Index<E> = firstVacant() else {
            throw .full
        }
        column.insert(consume element, at: slot.retag(Bit.self))
        return slot
    }

    /// Replaces the element at the specified slot and returns the old element.
    ///
    /// - Parameters:
    ///   - index: The slot index. Must be occupied.
    ///   - element: The new element to store.
    /// - Returns: The previous element.
    /// - Throws: `Slab.Error.vacant` if the slot is not occupied.
    @inlinable
    public mutating func update<E: ~Copyable>(
        at index: Index<E>,
        with element: consuming E
    ) throws(Error) -> E
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else {
            throw .vacant
        }
        return column.update(at: slot, with: consume element)
    }

    /// Removes all elements from the slab.
    @inlinable
    public mutating func removeAll<E: ~Copyable>()
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.removeAll()
    }
}
