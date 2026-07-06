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

import Finite_Bounded_Primitives
import Index_Primitives
import Slab_Inline_Primitive
import Slab_Primitives
import Testing

// [DS-027].1 reachability for the un-parked `Slab<E>.Inline<n>` door: the alias resolves and the
// inline-column op-pin set (construct / insert-at / remove-at / update / peek / firstVacant /
// isFull / isOccupied / removeAll / composed auto-insert) reaches the `Buffer.Slab.Inline` column
// for both Copyable and move-only elements, incl. fill-to-capacity.
//
// The slab value is `~Copyable`, so op results are bound to locals before `#expect` (the macro
// captures its receiver and cannot copy a move-only value).
//
// RELEASE-GUARD: the `Buffer.Slab.Inline` occupancy-bitmap write elides under `-O`
// (swift-issue-inlinearray-class-field-write-elision), so behavioral checks run DEBUG-only,
// matching the deinit suite.
@Suite(
    "Slab - Inline",
    .disabled(
        if: !_isDebugAssertConfiguration(),
        "release-blocked: swift-issue-inlinearray-class-field-write-elision (Slab<E>.Inline inline arm)"
    )
)
struct SlabInlineTests {

    @Test
    func `Copyable element surface — insert at, peek, update, remove`() throws {
        var slab = Slab<Int>.Inline<4>()
        let startEmpty = slab.isEmpty
        let startFull = slab.isFull()
        #expect(startEmpty)
        #expect(!startFull)

        let i0 = Index<Int>.Bounded<4>(0)
        let i1 = Index<Int>.Bounded<4>(1)

        try slab.insert(10, at: i0)
        try slab.insert(20, at: i1)
        let two = slab.count
        let occ0 = slab.isOccupied(at: i0)
        let peek0 = slab.peek(at: i0)
        #expect(two == Index<Int>.Count(2))
        #expect(occ0)
        #expect(peek0 == 10)

        let old = try slab.update(at: i1, with: 25)
        let peek1 = slab.peek(at: i1)
        #expect(old == 20)
        #expect(peek1 == 25)

        let removed = try slab.remove(at: i0)
        let occ0after = slab.isOccupied(at: i0)
        let peek0after = slab.peek(at: i0)
        #expect(removed == 10)
        #expect(!occ0after)
        #expect(peek0after == nil)
    }

    @Test
    func `Composed auto-insert returns stable index and fills to capacity`() throws {
        var slab = Slab<Int>.Inline<2>()

        let a: Index<Int>.Bounded<2> = try slab.insert(1)
        let b: Index<Int>.Bounded<2> = try slab.insert(2)
        let full = slab.isFull()
        #expect(a != b)
        #expect(full)

        // Fill-to-capacity: the next auto-insert overflows with `.full`.
        var overflowed = false
        do {
            _ = try slab.insert(3)
        } catch {
            overflowed = true
        }
        #expect(overflowed)

        slab.removeAll()
        let empty = slab.isEmpty
        #expect(empty)
    }

    struct Move: ~Copyable {
        let id: Int
    }

    @Test
    func `Move-only element surface — insert, remove reachable`() throws {
        var slab = Slab<Move>.Inline<4>()
        let i0 = Index<Move>.Bounded<4>(0)
        try slab.insert(Move(id: 7), at: i0)
        let occ = slab.isOccupied(at: i0)
        #expect(occ)
        let out = try slab.remove(at: i0)
        #expect(out.id == 7)
    }
}
