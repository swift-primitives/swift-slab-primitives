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

import Buffer_Slab_Primitives
public import Buffer_Slab_Inline_Primitives
import Index_Primitives
import Finite_Primitives
import Bit_Primitives

// MARK: - Occupancy Queries

extension Slab.Static where Element: ~Copyable {
    /// The number of currently occupied slots.
    @inlinable
    public var occupancy: Index<Element>.Count {
        _buffer.occupancy.retag(Element.self)
    }

    /// Whether all slots are empty.
    @inlinable
    public var isEmpty: Bool { _buffer.isEmpty }

    /// Whether all slots are occupied.
    @inlinable
    public var isFull: Bool { _buffer.isFull }

    /// Whether the slot at the given index is occupied.
    @inlinable
    public func isOccupied(at index: Index<Element>.Bounded<wordCount>) -> Bool {
        _buffer.isOccupied(at: index.retag(Bit.self))
    }

    /// Returns the first vacant (unoccupied) slot index, or `nil` if full.
    @inlinable
    public func firstVacant() -> Index<Element>.Bounded<wordCount>? {
        _buffer.firstVacant()?.retag(Element.self)
    }
}

// MARK: - Primitive Operations

extension Slab.Static where Element: ~Copyable {
    /// Inserts an element at the specified slot index.
    @inlinable
    public mutating func insert(
        _ element: consuming Element,
        at index: Index<Element>.Bounded<wordCount>
    ) throws(Slab<Element>.Error) {
        let slot = index.retag(Bit.self)
        guard !_buffer.isOccupied(at: slot) else {
            throw .occupied
        }
        _buffer.insert(consume element, at: slot)
    }

    /// Inserts an element at the specified slot index without occupancy checking.
    @inlinable
    public mutating func insert(
        _ element: consuming Element,
        __unchecked index: Index<Element>.Bounded<wordCount>
    ) {
        _buffer.insert(consume element, at: index.retag(Bit.self))
    }

    /// Removes and returns the element at the specified slot index.
    @inlinable
    public mutating func remove(
        at index: Index<Element>.Bounded<wordCount>
    ) throws(Slab<Element>.Error) -> Element {
        let slot = index.retag(Bit.self)
        guard _buffer.isOccupied(at: slot) else {
            throw .vacant
        }
        return _buffer.remove(at: slot)
    }

    /// Removes and returns the element at the specified slot index without occupancy checking.
    @inlinable
    public mutating func remove(
        __unchecked index: Index<Element>.Bounded<wordCount>
    ) -> Element {
        _buffer.remove(at: index.retag(Bit.self))
    }
}

// MARK: - Composed Operations

extension Slab.Static where Element: ~Copyable {
    /// Inserts an element at the first vacant slot and returns the slot index.
    @discardableResult
    @inlinable
    public mutating func insert(
        _ element: consuming Element
    ) throws(Slab<Element>.Error) -> Index<Element>.Bounded<wordCount> {
        guard let slot = firstVacant() else {
            throw .full
        }
        _buffer.insert(consume element, at: slot.retag(Bit.self))
        return slot
    }

    /// Replaces the element at the specified slot and returns the old element.
    @inlinable
    public mutating func update(
        at index: Index<Element>.Bounded<wordCount>,
        with element: consuming Element
    ) throws(Slab<Element>.Error) -> Element {
        let slot = index.retag(Bit.self)
        guard _buffer.isOccupied(at: slot) else {
            throw .vacant
        }
        return _buffer.update(at: slot, with: consume element)
    }

    /// Removes all elements from the slab.
    @inlinable
    public mutating func removeAll() {
        _buffer.removeAll()
    }
}

// MARK: - Drain
// NOTE: Drain conformance moved to separate Copyable module to avoid constraint poisoning
