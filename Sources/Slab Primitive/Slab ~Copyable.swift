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
import Buffer_Slab_Primitives
import Index_Primitives

// MARK: - Occupancy Queries

extension Slab where Element: ~Copyable {
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
    public func isOccupied(at index: Index<Element>) -> Bool {
        _buffer.isOccupied(at: index.retag(Bit.self))
    }

    /// Returns the first vacant (unoccupied) slot index, or `nil` if full.
    @inlinable
    public func firstVacant() -> Index<Element>? {
        _buffer.firstVacant()?.retag(Element.self)
    }
}

// MARK: - Primitive Operations (Consumer-Chosen)

extension Slab where Element: ~Copyable {
    /// Inserts an element at the specified slot index.
    ///
    /// - Parameters:
    ///   - element: The element to store.
    ///   - index: The slot index. Must be vacant.
    /// - Throws: `Slab.Error.occupied` if the slot is already occupied.
    @inlinable
    public mutating func insert(
        _ element: consuming Element,
        at index: Index<Element>
    ) throws(Slab.Error) {
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
        __unchecked index: Index<Element>
    ) {
        _buffer.insert(consume element, at: index.retag(Bit.self))
    }

    /// Removes and returns the element at the specified slot index.
    ///
    /// - Parameter index: The slot index. Must be occupied.
    /// - Returns: The element that was stored at the index.
    /// - Throws: `Slab.Error.vacant` if the slot is not occupied.
    @inlinable
    public mutating func remove(
        at index: Index<Element>
    ) throws(Slab.Error) -> Element {
        let slot = index.retag(Bit.self)
        guard _buffer.isOccupied(at: slot) else {
            throw .vacant
        }
        return _buffer.remove(at: slot)
    }

    /// Removes and returns the element at the specified slot index without occupancy checking.
    @inlinable
    public mutating func remove(
        __unchecked index: Index<Element>
    ) -> Element {
        _buffer.remove(at: index.retag(Bit.self))
    }
}

// MARK: - Composed Operations

extension Slab where Element: ~Copyable {
    /// Inserts an element at the first vacant slot and returns the slot index.
    ///
    /// Composed from `firstVacant()` + `insert(_:at:)`.
    ///
    /// - Parameter element: The element to store.
    /// - Returns: The slot index where the element was stored.
    /// - Throws: `Slab.Error.full` if no vacant slot exists.
    @discardableResult
    @inlinable
    public mutating func insert(
        _ element: consuming Element
    ) throws(Slab.Error) -> Index<Element> {
        guard let slot = firstVacant() else {
            throw .full
        }
        _buffer.insert(consume element, at: slot.retag(Bit.self))
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
    public mutating func update(
        at index: Index<Element>,
        with element: consuming Element
    ) throws(Slab.Error) -> Element {
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
