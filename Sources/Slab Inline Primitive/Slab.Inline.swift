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

public import Buffer_Primitive
public import Buffer_Protocol_Primitives
public import Buffer_Slab_Inline_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Slab_Primitive
public import Storage_Contiguous_Primitives

// MARK: - Slab<E>.Inline<n> — the inline (in-footprint) allocation variant ([DS-028] law 1)
//
// The W3 un-park of the parked `Slab.Static` (`Experiments/Slab Static (parked)/`). Under the
// tower an allocation variant is a front-door ALIAS over its column, never a hand-written type
// (D4.2). The reusable substrate — the `Buffer.Slab.Inline<n>` column — already lives in
// swift-buffer-slab-primitives with full public construction + ops; the un-park is this alias
// plus a second column-pinned op set (`Slab.Inline+Operations.swift`) delegating to it.

extension __Slab where S: ~Copyable, S: Buffer.`Protocol` {
    /// `Slab<E>.Inline<n>` — the inline (stack-allocated) fixed-capacity slab front door.
    ///
    /// An axis-CHANGING front-door alias ([DS-028] law 1): it re-points the allocation axis
    /// from the canonical Slab-buffer column's leaf to the allocation-independent
    /// `Store.Inline` leaf (via `Buffer.Slab.Inline<n>`), preserving the element (`S.Element`)
    /// and the Slab discipline. The fence is `where S: Buffer.Protocol` — the Slab seam that
    /// surfaces `S.Element`, satisfied by every canonical Slab carrier.
    ///
    /// **Units**: `Inline<n>` is an **ELEMENT/slot** count (`Store.Inline`'s `n`), not a byte
    /// budget ([DS-028] law 3). `Slab<Int>.Inline<4>` reserves exactly 4 `Int` slots inline in
    /// the value's own footprint (`@_rawLayout`), with no heap allocation. Fixed-capacity by
    /// construction: there is no growth op; `insert(_:)` throws `.full` when no slot is vacant.
    public typealias Inline<let n: Int> =
        __Slab<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<S.Element>>.Slab.Inline<n>>
}
