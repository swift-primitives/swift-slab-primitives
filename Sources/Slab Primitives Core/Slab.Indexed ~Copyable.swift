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
import Index_Primitives
import Bit_Primitives

// MARK: - Occupancy Queries

extension Slab.Indexed where Element: ~Copyable, Tag: ~Copyable {
    /// The number of currently occupied slots.
    @inlinable
    public var occupancy: Index<Tag>.Count {
        _base.occupancy.retag(Tag.self)
    }

    /// Whether all slots are empty.
    @inlinable
    public var isEmpty: Bool { _base.isEmpty }

    /// Whether all slots are occupied.
    @inlinable
    public var isFull: Bool { _base.isFull }

    /// Whether the slot at the given index is occupied.
    @inlinable
    public func isOccupied(at index: Index<Tag>) -> Bool {
        _base.isOccupied(at: index.retag(Element.self))
    }

    /// Returns the first vacant (unoccupied) slot index, or `nil` if full.
    @inlinable
    public func firstVacant() -> Index<Tag>? {
        _base.firstVacant()?.retag(Tag.self)
    }
}

// MARK: - Primitive Operations

extension Slab.Indexed where Element: ~Copyable, Tag: ~Copyable {
    /// Inserts an element at the specified slot index.
    @inlinable
    public mutating func insert(
        _ element: consuming Element,
        at index: Index<Tag>
    ) throws(Slab<Element>.Error) {
        try _base.insert(consume element, at: index.retag(Element.self))
    }

    /// Inserts an element at the specified slot index without occupancy checking.
    @inlinable
    public mutating func insert(
        _ element: consuming Element,
        __unchecked index: Index<Tag>
    ) {
        _base.insert(consume element, __unchecked: index.retag(Element.self))
    }

    /// Removes and returns the element at the specified slot index.
    @inlinable
    public mutating func remove(
        at index: Index<Tag>
    ) throws(Slab<Element>.Error) -> Element {
        try _base.remove(at: index.retag(Element.self))
    }

    /// Removes and returns the element at the specified slot index without occupancy checking.
    @inlinable
    public mutating func remove(
        __unchecked index: Index<Tag>
    ) -> Element {
        _base.remove(__unchecked: index.retag(Element.self))
    }
}

// MARK: - Composed Operations

extension Slab.Indexed where Element: ~Copyable, Tag: ~Copyable {
    /// Inserts an element at the first vacant slot and returns the typed slot index.
    @discardableResult
    @inlinable
    public mutating func insert(
        _ element: consuming Element
    ) throws(Slab<Element>.Error) -> Index<Tag> {
        try _base.insert(consume element).retag(Tag.self)
    }

    /// Replaces the element at the specified slot and returns the old element.
    @inlinable
    public mutating func update(
        at index: Index<Tag>,
        with element: consuming Element
    ) throws(Slab<Element>.Error) -> Element {
        try _base.update(at: index.retag(Element.self), with: consume element)
    }

    /// Removes all elements from the slab.
    @inlinable
    public mutating func removeAll() {
        _base.removeAll()
    }
}

// MARK: - Drain
// NOTE: Drain conformance moved to separate Copyable module to avoid constraint poisoning
