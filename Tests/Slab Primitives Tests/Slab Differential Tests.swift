import Testing

@testable import Slab_Primitives

private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }
}

extension SplitMix64 {
    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@Suite
struct `Slab Differential Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}

    @Test
    func `600 mixed ops: duplicates, interleaved insert/remove/update/peek, slot reuse`() throws {
        var rng = SplitMix64(seed: 0x5EED_5148_ABCD_0001)
        var slab = Slab<Int>(minimumCapacity: 64)

        var live: [(index: Index<Int>, value: Int)] = []

        var inserts = 0
        var removes = 0
        var updates = 0
        var fullHits = 0

        for _ in 0..<600 {

            let stepCount = Int(clamping: slab.count)
            let stepOccupancy = Int(clamping: slab.occupancy)
            let stepEmpty = slab.isEmpty
            #expect(stepCount == live.count)
            #expect(stepOccupancy == live.count)
            #expect(stepEmpty == live.isEmpty)

            let roll = Int(rng.next() % 100)

            if live.isEmpty || (roll < 55) {

                let value = Int(rng.next() % 32)
                let full = slab.isFull()
                if full {
                    fullHits += 1

                    #expect(throws: Slab<Int>.Error.full) { _ = try slab.insert(value) }
                } else {
                    let index = try slab.insert(value)

                    let fresh = !live.contains { $0.index == index }
                    #expect(fresh)
                    live.append((index, value))
                    let occupied = slab.isOccupied(at: index)
                    #expect(occupied)
                    inserts += 1
                }
            } else if roll < 78 {

                let p = Int(rng.next() % UInt64(live.count))
                let (idx, expected) = live[p]
                let got = try slab.remove(at: idx)
                #expect(got == expected)
                live.remove(at: p)
                let stillOccupied = slab.isOccupied(at: idx)
                #expect(!stillOccupied)
                removes += 1
            } else if roll < 90 {

                let p = Int(rng.next() % UInt64(live.count))
                let (idx, expected) = live[p]
                let newValue = Int(rng.next() % 32)
                let old = try slab.update(at: idx, with: newValue)
                #expect(old == expected)
                live[p].value = newValue
                updates += 1
            } else {

                let p = Int(rng.next() % UInt64(live.count))
                let (idx, expected) = live[p]
                let peeked = slab.peek(at: idx)
                #expect(peeked == expected)
            }
        }

        for (idx, expected) in live {
            let peeked = slab.peek(at: idx)
            #expect(peeked == expected)
            let got = try slab.remove(at: idx)
            #expect(got == expected)
        }
        let emptyAfter = slab.isEmpty
        #expect(emptyAfter)
        let finalCount = Int(clamping: slab.count)
        #expect(finalCount == 0)

        #expect(inserts >= 200)
        #expect(removes >= 60)
        #expect(updates >= 30)
        #expect(fullHits >= 1)
    }
}
