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

import Buffer_Primitives_Test_Support
import Testing

@testable import Slab_Primitives

@Suite("Slab")
struct SlabTests {

    // MARK: - Initialization

    @Test
    func `init creates empty slab`() {
        let slab = Slab<Int>()
        #expect(slab.isEmpty == true)
        #expect(slab.occupancy == .zero)
    }

    @Test
    func `init with minimum capacity`() {
        let slab = Slab<Int>(minimumCapacity: 10)
        #expect(slab.isEmpty == true)
        #expect(slab.occupancy == .zero)
    }

    // MARK: - Insert and Remove

    @Test
    func `insert at index roundtrip`() throws {
        var slab = Slab<Int>(minimumCapacity: 3)
        let index: Index<Int> = 0
        try slab.insert(42, at: index)

        #expect(slab.isOccupied(at: index) == true)
        #expect(slab.occupancy == 1)

        let removed = try slab.remove(at: index)
        #expect(removed == 42)
        #expect(slab.isEmpty == true)
    }

    @Test
    func `insert auto finds first vacant`() throws {
        var slab = Slab<Int>(minimumCapacity: 3)
        let i0 = try slab.insert(10)
        let i1 = try slab.insert(20)
        let i2 = try slab.insert(30)

        #expect(slab.occupancy == 3)
        #expect(try slab.remove(at: i0) == 10)
        #expect(try slab.remove(at: i1) == 20)
        #expect(try slab.remove(at: i2) == 30)
        #expect(slab.isEmpty == true)
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

        #expect(slab.peek(at: index) == 42)
        #expect(slab.isOccupied(at: index) == true)
    }

    @Test
    func `peek vacant returns nil`() {
        let slab = Slab<Int>(minimumCapacity: 1)
        let index: Index<Int> = 0
        #expect(slab.peek(at: index) == nil)
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
        while !slab.isFull {
            slab.insert(0, __unchecked: slab.firstVacant()!)
        }
        #expect(slab.isFull == true)
        #expect(slab.firstVacant() == nil)
    }

    // MARK: - Slot Reuse

    @Test
    func `slot reuse after removal`() throws {
        var slab = Slab<Int>(minimumCapacity: 4)
        let slot = try slab.insert(10)
        _ = try slab.remove(at: slot)
        try slab.insert(20, at: slot)
        #expect(try slab.remove(at: slot) == 20)
    }

    // MARK: - Remove All

    @Test
    func `removeAll clears all slots`() throws {
        var slab = Slab<Int>(minimumCapacity: 3)
        _ = try slab.insert(10)
        _ = try slab.insert(20)
        _ = try slab.insert(30)

        slab.removeAll()
        #expect(slab.isEmpty == true)
        #expect(slab.occupancy == .zero)
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
        #expect(slab.isEmpty == true)
        #expect(drained.sorted() == [10, 20, 30])
    }
}
