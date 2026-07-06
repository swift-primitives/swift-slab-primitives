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

// MARK: - Slab (the ADT tier — a sparse, stable-index slot store over the COLUMN)
//
// ADT Tower W2 reshape (Research/adt-tower.md §9.3 Slab row, adt-tower.md:1492;
// SEAT-dispatched 2026-07-05). The prior shape-E core (element-generic, hand-rolled
// over `Buffer.Slab.Bounded`) is hoisted to the bound-free carrier:
//   1. thin bound-free carrier `__Slab<S: ~Copyable>` (hoisted per
//      [API-IMPL-009]/[PKG-NAME-006]; the public spelling is the front-door alias
//      `Slab<E>` in Slab.FrontDoor.swift, [DS-028]);
//   2. seam-generic observability (`count`/`isEmpty`) written ONCE over
//      `Buffer.Protocol` — the Slab column conforms `Buffer.Protocol` ONLY (it is a
//      BUFFER-tier discipline, not a `Store.Protocol` storage column: [DS-029]
//      column-pinned where the seam does not reach);
//   3. the sparse / stable-index ops (insert-at / remove-at / firstVacant /
//      occupancy / …) COLUMN-PINNED to the default Slab-buffer column, since the
//      bitmap surface is column-specific and not seam vocabulary.
//
// DISCIPLINE DETERMINATION (§9.3 under-determination, mechanically forced):
// `Slab` rides the SLAB-BUFFER column discipline, NOT the Generational storage
// discipline. Slab is a Buffer-tier discipline (`𝔻 = {Linear,Ring,Slab,Linked,Slots}`,
// adt-tower.md:1012/§2-D1:291); Generational is a Storage-tier discipline that
// `SlotMap` rides (adt-tower.md:146) — a DIFFERENT discipline under a different
// semantic surface is a SIBLING FAMILY, never a variant (adt-tower.md:291). The
// current type wraps `Buffer.Slab.Bounded`; the canonical front door pins exactly
// that (Slab.FrontDoor.swift). The `.Inline`/`.Small` allocation front doors and a
// growable base column are consumer-pulled / W3 items (§9.3 W3 row, adt-tower.md:1376).

// MARK: 1. The carrier (thin, bound-free; hoisted per [API-IMPL-009])

/// A sparse, stable-index slot store — the semantic ADT over an explicit storage COLUMN.
///
/// `__Slab` is the bound-free carrier ([DS-025]): its column parameter `S` is bound
/// `~Copyable` **only**; every capability (observability, the sparse slot ops,
/// construction) attaches by conditional `@inlinable` extension keyed on the seams the
/// column conforms (D3) or pinned to the concrete column where the surface is
/// column-specific (D3 / [DS-029]). The PUBLIC spelling of the family is the front-door
/// alias `Slab<E>` (canonical), declared in `Slab.FrontDoor.swift` ([DS-028]); the
/// hoisted name never appears in consumer signatures.
///
/// `Slab` provides O(1) insert and remove at consumer-chosen indices, with O(word)
/// first-vacant scan via a bitmap. Elements can be `~Copyable`. The consumer-chosen
/// `insert(_:at:)` is the primitive operation; auto-insert `insert(_:)` is composed
/// from `firstVacant()` + `insert(_:at:)`.
///
/// Copyability flows from the column: `__Slab<S>` is `Copyable` exactly when `S` is
/// (the default Slab-buffer column is move-only by design — it owns a bitmap-driven
/// teardown box).
@_documentation(visibility: public)  // symbolgraph-extract drops __-prefixed decls otherwise
@frozen
public struct __Slab<S: ~Copyable>: ~Copyable {

    /// The storage column — the default move-only Slab buffer (bitmap occupancy +
    /// relocated cleanup oracle).
    ///
    /// The ADT is a thin semantic discipline over it; it carries NO deinit
    /// (teardown lives in the column's box).
    @usableFromInline
    package var column: S

    /// Wraps an existing column.
    @inlinable
    public init(column: consuming S) { self.column = column }

    /// Consumes the slab, yielding its storage column.
    @inlinable
    public consuming func take() -> S { column }
}

extension __Slab: Copyable where S: Copyable {}
extension __Slab: Sendable where S: Sendable & ~Copyable {}
