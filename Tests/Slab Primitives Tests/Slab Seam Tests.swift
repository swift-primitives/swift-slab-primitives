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

// MARK: - [DS-024]-STYLE stable-index laws (§9.3 Slab row, adt-tower.md:1492)
//
// The Slab column conforms `Buffer.Protocol` ONLY (a Buffer-tier discipline), NOT
// `Store.Protocol`, so the Store-tier `Seam.Ledger.violations` harness (heap/linear's
// [DS-024] law) does not apply to it. §9.3 asks for "[DS-024]-STYLE" laws — for a
// stable-index family that is the STABLE-INDEX contract itself, proven directly:
//
//   L1  count/occupancy honesty: count == occupancy == #occupied through any history.
//   L2  stable index: an index is invalidated ONLY by removing ITS slot — other slots'
//       insert/remove/update never move or alias it.
//   L3  slot reuse: a removed slot becomes first-vacant again and is reusable.
//   L4  capacity fence: insert(_:) throws .full at capacity; addressed misses throw.
//
// Move-only discipline (playbook §5): every observation of `slab` is bound to a local.

@Suite("Slab seam laws (stable-index)")
struct SlabSeamTests {

    // L1 — the count/occupancy ledger stays honest through insert/remove/update.
    @Test("[DS-024]-style L1: count == occupancy == #occupied at every step")
    func countOccupancyHonesty() throws {
        var slab = Slab<Int>(minimumCapacity: 16)
        let empty0 = slab.isEmpty
        let count0 = Int(clamping: slab.count)
        let occ0 = Int(clamping: slab.occupancy)
        #expect(empty0)
        #expect(count0 == 0)
        #expect(occ0 == 0)

        let i0 = try slab.insert(10)
        let i1 = try slab.insert(20)
        let i2 = try slab.insert(30)
        let count3 = Int(clamping: slab.count)
        let occ3 = Int(clamping: slab.occupancy)
        #expect(count3 == 3)
        #expect(occ3 == 3)

        _ = try slab.remove(at: i1)
        let count2 = Int(clamping: slab.count)
        let occ2 = Int(clamping: slab.occupancy)
        #expect(count2 == 2)
        #expect(occ2 == 2)

        // update does not change the ledger.
        _ = try slab.update(at: i0, with: 11)
        let countAfterUpdate = Int(clamping: slab.count)
        #expect(countAfterUpdate == 2)

        _ = try slab.remove(at: i0)
        _ = try slab.remove(at: i2)
        let emptyEnd = slab.isEmpty
        let countEnd = Int(clamping: slab.count)
        #expect(emptyEnd)
        #expect(countEnd == 0)
    }

    // L2 — the defining law: removing one slot never invalidates the others.
    @Test("[DS-024]-style L2: an index survives other slots' removal (stable index)")
    func stableIndexAcrossOtherRemovals() throws {
        var slab = Slab<Int>(minimumCapacity: 16)
        let a = try slab.insert(100)
        let b = try slab.insert(200)
        let c = try slab.insert(300)

        // Remove the MIDDLE slot. Unlike Array.remove(at:), the surviving indices do NOT
        // shift — a and c still address exactly their original elements.
        let removedB = try slab.remove(at: b)
        #expect(removedB == 200)
        let peekA = slab.peek(at: a)
        let peekC = slab.peek(at: c)
        let occA = slab.isOccupied(at: a)
        let occC = slab.isOccupied(at: c)
        let occB = slab.isOccupied(at: b)
        #expect(peekA == 100)
        #expect(peekC == 300)
        #expect(occA)
        #expect(occC)
        #expect(!occB)

        // Removing a survivor still leaves the other survivor intact.
        _ = try slab.remove(at: a)
        let peekCAfter = slab.peek(at: c)
        #expect(peekCAfter == 300)
        let removedC = try slab.remove(at: c)
        #expect(removedC == 300)
    }

    // L3 — a removed slot is reused (first-vacant returns it; re-insert lands there).
    @Test("[DS-024]-style L3: slot reuse after removal")
    func slotReuse() throws {
        var slab = Slab<Int>(minimumCapacity: 16)
        let a = try slab.insert(1)
        _ = try slab.insert(2)
        _ = try slab.remove(at: a)

        // The freed slot is the first vacant one again.
        let vacant = slab.firstVacant()
        #expect(vacant == a)

        // Re-inserting reuses it (consumer-chosen path).
        try slab.insert(9, at: a)
        let peekReused = slab.peek(at: a)
        #expect(peekReused == 9)
        let removedReused = try slab.remove(at: a)
        #expect(removedReused == 9)
    }

    // L4 — capacity fence + addressed-miss errors.
    @Test("[DS-024]-style L4: capacity fence and addressed-miss errors")
    func capacityFenceAndMisses() throws {
        var slab = Slab<Int>(minimumCapacity: 1)
        // Fill to capacity via the __unchecked fast path.
        while !slab.isFull() {
            slab.insert(0, __unchecked: slab.firstVacant()!)
        }
        // insert(_:) at capacity throws .full.
        #expect(throws: Slab<Int>.Error.full) { _ = try slab.insert(7) }
        let vacant = slab.firstVacant()
        #expect(vacant == nil)

        // Addressed miss on a vacant slot throws .vacant.
        var fresh = Slab<Int>(minimumCapacity: 4)
        let idx: Index<Int> = 0
        #expect(throws: Slab<Int>.Error.vacant) { _ = try fresh.remove(at: idx) }
        #expect(throws: Slab<Int>.Error.vacant) { _ = try fresh.update(at: idx, with: 1) }

        // Occupied slot rejects a second insert with .occupied.
        let live = try fresh.insert(5)
        #expect(throws: Slab<Int>.Error.occupied) { try fresh.insert(6, at: live) }
    }
}
