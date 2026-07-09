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

import Testing

@testable import Slab_Primitives

// Move-only discipline (playbook §5): the canonical `Slab<E>` is move-only, so a bare
// `#expect(slab.method(…))` would capture `slab` (the `#expect` function-call check
// requires the receiver `Copyable`). Every observation is bound to a local first.

@Suite
struct `Slab Tests` {

    // MARK: - Initialization

    @Test
    func `init creates empty slab`() {
        let slab = Slab<Int>()
        let empty = slab.isEmpty
        let occ = slab.occupancy
        #expect(empty == true)
        #expect(occ == .zero)
    }

    @Test
    func `init with minimum capacity`() {
        let slab = Slab<Int>(minimumCapacity: 10)
        let empty = slab.isEmpty
        let occ = slab.occupancy
        #expect(empty == true)
        #expect(occ == .zero)
    }

    // MARK: - Insert and Remove

    @Test
    func `insert at index roundtrip`() throws {
        var slab = Slab<Int>(minimumCapacity: 3)
        let index: Index<Int> = 0
        try slab.insert(42, at: index)

        let occupied = slab.isOccupied(at: index)
        let occ = slab.occupancy
        #expect(occupied == true)
        #expect(occ == 1)

        let removed = try slab.remove(at: index)
        let empty = slab.isEmpty
        #expect(removed == 42)
        #expect(empty == true)
    }

    @Test
    func `insert auto finds first vacant`() throws {
        var slab = Slab<Int>(minimumCapacity: 3)
        let i0 = try slab.insert(10)
        let i1 = try slab.insert(20)
        let i2 = try slab.insert(30)

        let occ = slab.occupancy
        #expect(occ == 3)
        let r0 = try slab.remove(at: i0)
        let r1 = try slab.remove(at: i1)
        let r2 = try slab.remove(at: i2)
        #expect(r0 == 10)
        #expect(r1 == 20)
        #expect(r2 == 30)
        let empty = slab.isEmpty
        #expect(empty == true)
    }

    @Test
    func `insert occupied throws`() throws {
        var slab = Slab<Int>(minimumCapacity: 1)
        let index = try slab.insert(42)

        #expect(throws: Slab<Int>.Error.occupied) {
            try slab.insert(99, at: index)
        }
    }

    @Test
    func `insert full throws`() throws {
        var slab = Slab<Int>(minimumCapacity: 1)
        _ = try slab.insert(42)

        #expect(throws: Slab<Int>.Error.full) {
            try slab.insert(99)
        }
    }

    @Test
    func `remove vacant throws`() {
        var slab = Slab<Int>(minimumCapacity: 1)
        let index: Index<Int> = 0

        #expect(throws: Slab<Int>.Error.vacant) {
            try slab.remove(at: index)
        }
    }

    // MARK: - Update

    @Test
    func `update swaps element`() throws {
        var slab = Slab<Int>(minimumCapacity: 1)
        let index = try slab.insert(42)

        let old = try slab.update(at: index, with: 99)
        #expect(old == 42)

        let current = try slab.remove(at: index)
        #expect(current == 99)
    }

    @Test
    func `update vacant throws`() {
        var slab = Slab<Int>(minimumCapacity: 1)
        let index: Index<Int> = 0

        #expect(throws: Slab<Int>.Error.vacant) {
            try slab.update(at: index, with: 42)
        }
    }

    // MARK: - Peek

    @Test
    func `peek returns element without removing`() throws {
        var slab = Slab<Int>(minimumCapacity: 1)
        let index = try slab.insert(42)

        let peeked = slab.peek(at: index)
        let occupied = slab.isOccupied(at: index)
        #expect(peeked == 42)
        #expect(occupied == true)
    }

    @Test
    func `peek vacant returns nil`() {
        let slab = Slab<Int>(minimumCapacity: 1)
        let index: Index<Int> = 0
        let peeked = slab.peek(at: index)
        #expect(peeked == nil)
    }

    // MARK: - Occupancy Queries

    @Test
    func `firstVacant returns first empty slot`() throws {
        var slab = Slab<Int>(minimumCapacity: 3)
        let i0 = try slab.insert(10)
        _ = try slab.insert(20)

        _ = try slab.remove(at: i0)

        let vacant = slab.firstVacant()
        #expect(vacant == i0)
    }

    @Test
    func `isFull when all slots occupied`() throws {
        var slab = Slab<Int>(minimumCapacity: 2)
        // minimumCapacity rounds up to word-aligned slot count,
        // so fill until actually full.
        while !slab.isFull() {
            slab.insert(0, __unchecked: slab.firstVacant()!)
        }
        let full = slab.isFull()
        let vacant = slab.firstVacant()
        #expect(full == true)
        #expect(vacant == nil)
    }

    // MARK: - Slot Reuse

    @Test
    func `slot reuse after removal`() throws {
        var slab = Slab<Int>(minimumCapacity: 4)
        let slot = try slab.insert(10)
        _ = try slab.remove(at: slot)
        try slab.insert(20, at: slot)
        let removed = try slab.remove(at: slot)
        #expect(removed == 20)
    }

    // MARK: - Remove All

    @Test
    func `removeAll clears all slots`() throws {
        var slab = Slab<Int>(minimumCapacity: 3)
        _ = try slab.insert(10)
        _ = try slab.insert(20)
        _ = try slab.insert(30)

        slab.removeAll()
        let empty = slab.isEmpty
        let occ = slab.occupancy
        #expect(empty == true)
        #expect(occ == .zero)
    }

    // MARK: - Drain

    @Test
    func `drain removes all elements`() throws {
        var slab = Slab<Int>(minimumCapacity: 3)
        _ = try slab.insert(10)
        _ = try slab.insert(20)
        _ = try slab.insert(30)

        var drained: [Int] = []
        slab.drain { drained.append($0) }
        let empty = slab.isEmpty
        #expect(empty == true)
        #expect(drained.sorted() == [10, 20, 30])
    }
}
