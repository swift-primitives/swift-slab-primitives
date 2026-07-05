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
public import Buffer_Slab_Primitives
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Slab_Primitive
public import Storage_Contiguous_Primitives

// MARK: - Non-Destructive Read (column-pinned; Copyable element)

extension __Slab where S: ~Copyable {
    /// Returns the element at the specified slot without removing it, or `nil` if the
    /// slot is vacant.
    ///
    /// A non-destructive read returns the element BY COPY, so it is available only for
    /// `Copyable` elements (`E` here is implicitly `Copyable`); a `~Copyable` element
    /// cannot be observed by copy — remove it, or use the mutating ops.
    @inlinable
    public func peek<E>(at index: Index<E>) -> E?
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        let slot = index.retag(Bit.self)
        guard column.isOccupied(at: slot) else { return nil }
        return column.peek(at: slot)
    }
}
