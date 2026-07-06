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
public import Buffer_Primitive
public import Buffer_Slab_Inline_Primitives
public import Finite_Bounded_Primitives
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Slab_Primitive
public import Storage_Contiguous_Primitives

// The inline-column op set for `__Slab` — the second column-pinned op set the tower calls for
// (D4.3 / [DS-029]: the sparse bitmap surface is column-specific, not seam vocabulary, so each
// column pins its own). Faithful re-home of the parked `Slab.Static` surface (hand `_buffer` →
// carrier `column`); the compile-time-dimensioned slot index `Index<E>.Bounded<n>` is the
// natural addressing for an inline slab (the Array `.Bounded` deletion pointed exactly here:
// "Index<E>.Bounded<N> + the inline column"). Seam observability (`count`/`occupancy`/`isEmpty`)
// already rides `Buffer.Protocol` in the core (`Slab ~Copyable.swift`); this file adds only the
// column-specific occupancy queries + mutations.

// MARK: - Construction

extension __Slab where S: ~Copyable {
    /// Creates an empty inline slab with all `n` slots vacant — no heap allocation.
    @inlinable
    public init<E: ~Copyable, let n: Int>()
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        self.init(column: Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline())
    }
}

// MARK: - Occupancy queries (column-pinned; the sparse bitmap surface)

extension __Slab where S: ~Copyable {
    /// Whether all slots are occupied.
    @inlinable
    public func isFull<E: ~Copyable, let n: Int>() -> Bool
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.isFull
    }

    /// Whether the slot at the given index is occupied.
    @inlinable
    public func isOccupied<E: ~Copyable, let n: Int>(at index: Index<E>.Bounded<n>) -> Bool
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.isOccupied(at: index.retag(Bit.self))
    }

    /// Returns the first vacant (unoccupied) slot index, or `nil` if full.
    @inlinable
    public func firstVacant<E: ~Copyable, let n: Int>() -> Index<E>.Bounded<n>?
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.firstVacant()?.retag(E.self)
    }
}

// MARK: - Primitive operations (consumer-chosen; column-pinned)

extension __Slab where S: ~Copyable {
    /// Inserts an element at the specified slot index.
    ///
    /// - Throws: `Slab.Error.occupied` if the slot is already occupied.
    @inlinable
    public mutating func insert<E: ~Copyable, let n: Int>(
        _ element: consuming E,
        at index: Index<E>.Bounded<n>
    ) throws(Error)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        let slot = index.retag(Bit.self)
        guard !column.isOccupied(at: slot) else { throw .occupied }
        column.insert(consume element, at: slot)
    }

    /// Inserts an element at the specified slot index without occupancy checking.
    @inlinable
    public mutating func insert<E: ~Copyable, let n: Int>(
        _ element: consuming E,
        __unchecked index: Index<E>.Bounded<n>
    ) where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.insert(consume element, at: index.retag(Bit.self))
    }

    /// Removes and returns the element at the specified slot index.
    ///
    /// - Throws: `Slab.Error.vacant` if the slot is not occupied.
    @inlinable
    public mutating func remove<E: ~Copyable, let n: Int>(
        at index: Index<E>.Bounded<n>
    ) throws(Error) -> E
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else { throw .vacant }
        return column.remove(at: slot)
    }

    /// Removes and returns the element at the specified slot index without occupancy checking.
    @inlinable
    public mutating func remove<E: ~Copyable, let n: Int>(
        __unchecked index: Index<E>.Bounded<n>
    ) -> E where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.remove(at: index.retag(Bit.self))
    }
}

// MARK: - Composed operations (column-pinned)

extension __Slab where S: ~Copyable {
    /// Inserts an element at the first vacant slot and returns the slot index.
    ///
    /// Composed from `firstVacant()` + `insert(_:at:)`.
    ///
    /// - Throws: `Slab.Error.full` if no vacant slot exists.
    @discardableResult
    @inlinable
    public mutating func insert<E: ~Copyable, let n: Int>(
        _ element: consuming E
    ) throws(Error) -> Index<E>.Bounded<n>
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        guard let slot: Index<E>.Bounded<n> = firstVacant() else { throw .full }
        column.insert(consume element, at: slot.retag(Bit.self))
        return slot
    }

    /// Replaces the element at the specified slot and returns the old element.
    ///
    /// - Throws: `Slab.Error.vacant` if the slot is not occupied.
    @inlinable
    public mutating func update<E: ~Copyable, let n: Int>(
        at index: Index<E>.Bounded<n>,
        with element: consuming E
    ) throws(Error) -> E
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else { throw .vacant }
        return column.update(at: slot, with: consume element)
    }

    /// Removes all elements from the slab.
    @inlinable
    public mutating func removeAll<E: ~Copyable, let n: Int>()
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        column.removeAll()
    }
}

// MARK: - Non-destructive read (Copyable element arm)

extension __Slab where S: ~Copyable {
    /// Returns the element at the specified slot without removing it, or `nil` if vacant.
    @inlinable
    public func peek<E, let n: Int>(at index: Index<E>.Bounded<n>) -> E?
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Inline<n> {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else { return nil }
        return column.peek(at: slot)
    }
}
