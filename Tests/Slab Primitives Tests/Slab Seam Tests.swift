import Testing

@testable import Slab_Primitives

@Suite
struct `Slab Seam Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}

    @Test
    func `[DS-024]-style L1: count == occupancy == #occupied at every step`() throws {
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

    @Test
    func `[DS-024]-style L2: an index survives other slots' removal (stable index)`() throws {
        var slab = Slab<Int>(minimumCapacity: 16)
        let a = try slab.insert(100)
        let b = try slab.insert(200)
        let c = try slab.insert(300)

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

        _ = try slab.remove(at: a)
        let peekCAfter = slab.peek(at: c)
        #expect(peekCAfter == 300)
        let removedC = try slab.remove(at: c)
        #expect(removedC == 300)
    }

    @Test
    func `[DS-024]-style L3: slot reuse after removal`() throws {
        var slab = Slab<Int>(minimumCapacity: 16)
        let a = try slab.insert(1)
        _ = try slab.insert(2)
        _ = try slab.remove(at: a)

        let vacant = slab.firstVacant()
        #expect(vacant == a)

        try slab.insert(9, at: a)
        let peekReused = slab.peek(at: a)
        #expect(peekReused == 9)
        let removedReused = try slab.remove(at: a)
        #expect(removedReused == 9)
    }

    @Test
    func `[DS-024]-style L4: capacity fence and addressed-miss errors`() throws {
        var slab = Slab<Int>(minimumCapacity: 1)

        while !slab.isFull() {

            slab.insert(0, __unchecked: slab.firstVacant()!)
        }

        #expect(throws: Slab<Int>.Error.full) { _ = try slab.insert(7) }
        let vacant = slab.firstVacant()
        #expect(vacant == nil)

        var fresh = Slab<Int>(minimumCapacity: 4)
        let idx: Index<Int> = 0
        #expect(throws: Slab<Int>.Error.vacant) { _ = try fresh.remove(at: idx) }
        #expect(throws: Slab<Int>.Error.vacant) { _ = try fresh.update(at: idx, with: 1) }

        let live = try fresh.insert(5)
        #expect(throws: Slab<Int>.Error.occupied) { try fresh.insert(6, at: live) }
    }
}
