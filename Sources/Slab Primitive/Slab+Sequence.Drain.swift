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
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives

// MARK: - Drain (consuming iteration; column-pinned)
//
// Drain is a COLUMN-PINNED method, not a `Sequence.Drain.Protocol` conformance: a
// conditional conformance on the carrier `__Slab` cannot bind the fresh element
// parameter `E` that the concrete column mentions (`S == …Contiguous<E>…`), and the
// `Property<Sequence.Drain, Self>.Inout` accessor needs that conformance. The tower
// pattern for column-specific iteration is a pinned method (cf. `SlotMap.forEach`).

extension __Slab where S: ~Copyable {
    /// Consuming iteration over all occupied slots, in slot order.
    ///
    /// Each occupied element is moved out and handed to `body`; the slab is empty
    /// afterward.
    @inlinable
    public mutating func drain<E: ~Copyable>(_ body: (consuming E) -> Void)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded {
        column.drain(body)
    }
}
