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
public import Storage_Contiguous_Primitives
public import Memory_Heap_Primitives
public import Memory_Allocator_Primitive

// MARK: - Slab<E> — the CANONICAL front door ([DS-028])

/// A sparse, stable-index slot store over the default column: the fixed-capacity,
/// heap-allocated Slab buffer with bitmap occupancy (`Buffer.Slab.Bounded`).
///
/// This is the canonical front-door alias ([DS-028]) — the sanctioned [API-NAME-004]
/// generic-instantiation exception that pins the default column so consumers spell
/// `Slab<Element>`, never the carrier `__Slab` or a full column. The alias fully
/// specializes: conformances, the pinned constructors, and `~Copyable` elements all
/// flow through it with zero forwarding and zero runtime cost.
///
/// ```swift
/// var s = Slab<Int>(minimumCapacity: 4)   // fixed-capacity move-only slab (this alias)
/// let i = try s.insert(42)                 // first-vacant insert -> stable index
/// let x = try s.remove(at: i)              // 42 (the index is stable across other ops)
/// ```
///
/// ## Discipline (mechanically forced — §9.3 Slab row, adt-tower.md:1492)
///
/// `Slab` rides the SLAB-BUFFER discipline (a Buffer-tier discipline), **not** the
/// Generational storage discipline that `SlotMap` rides (adt-tower.md:146) — the two are
/// SIBLING families along the discipline axis (adt-tower.md:291), never variants. The
/// `.Bounded` column is what the shape-E `Slab` wrapped on main; the front door preserves
/// exactly that (fixed-capacity semantics: `insert(_:)` throws `.full` when no slot is
/// vacant). The growable base column and the `Small`/`Inline` allocation front doors
/// (`Slab<E>.Inline<n>`) are consumer-pulled / W3 items (§9.3 W3 row, adt-tower.md:1376).
public typealias Slab<E: ~Copyable> =
    __Slab<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Slab.Bounded>
