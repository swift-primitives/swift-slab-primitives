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

// MARK: - Differential test vs a stable-index oracle (template law: adt-tower.md:1491)
//
// The randomized floor every reshaped family ships (§9.3 Slab row: "stable-index laws
// in [DS-024]-style tests"). For a stable-index/handle family the oracle is keyed by the
// minted index (mirroring slot-map's suite shape): a `[(index, expected)]` shadow that a
// trivially-correct model keeps in lock-step. The workload is long (>= 600 ops),
// duplicate-laden, interleaved insert/remove/update/peek, and — since the Slab column is
// FIXED-CAPACITY — cycles fill/drain so slot REUSE is exercised heavily (the stable-index
// invariant: an index is invalidated ONLY by removing ITS slot, never by other removals).
// Deterministic (seeded), so a failure reproduces exactly.
//
// Move-only discipline (playbook §5): every observation of the move-only `slab` is bound
// to a local before `#expect`.

/// SplitMix64 — a tiny deterministic `RandomNumberGenerator` (no `SystemRNG`).
private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@Suite("Slab differential (vs stable-index oracle)")
struct SlabDifferentialTests {

    @Test("600 mixed ops: duplicates, interleaved insert/remove/update/peek, slot reuse")
    func differentialAgainstIndexOracle() throws {
        var rng = SplitMix64(seed: 0x5EED_5148_ABCD_0001)
        var slab = Slab<Int>(minimumCapacity: 64)   // fixed capacity -> fill/drain cycling

        // The oracle: the exact set of live (index, value) pairs. Trivially correct.
        var live: [(index: Index<Int>, value: Int)] = []

        var inserts = 0
        var removes = 0
        var updates = 0
        var fullHits = 0

        for _ in 0..<600 {
            // count/occupancy honesty holds at EVERY step.
            let stepCount = Int(clamping: slab.count)
            let stepOccupancy = Int(clamping: slab.occupancy)
            let stepEmpty = slab.isEmpty
            #expect(stepCount == live.count)
            #expect(stepOccupancy == live.count)
            #expect(stepEmpty == live.isEmpty)

            let roll = Int(rng.next() % 100)

            if live.isEmpty || (roll < 55) {
                // INSERT (first-vacant). Small value range => many duplicates.
                let value = Int(rng.next() % 32)
                let full = slab.isFull()
                if full {
                    fullHits += 1
                    // insert(_:) must throw .full when no slot is vacant.
                    #expect(throws: Slab<Int>.Error.full) { _ = try slab.insert(value) }
                } else {
                    let index = try slab.insert(value)
                    // The minted slot must have been vacant (stable-index: no aliasing).
                    let fresh = !live.contains { $0.index == index }
                    #expect(fresh)
                    live.append((index, value))
                    let occupied = slab.isOccupied(at: index)
                    #expect(occupied)
                    inserts += 1
                }
            } else if roll < 78 {
                // REMOVE a random live slot; the returned element matches the oracle, and
                // every OTHER live index stays valid (checked on subsequent iterations).
                let p = Int(rng.next() % UInt64(live.count))
                let (idx, expected) = live[p]
                let got = try slab.remove(at: idx)
                #expect(got == expected)
                live.remove(at: p)
                let stillOccupied = slab.isOccupied(at: idx)
                #expect(!stillOccupied)
                removes += 1
            } else if roll < 90 {
                // UPDATE a random live slot; returns the old element, installs the new.
                let p = Int(rng.next() % UInt64(live.count))
                let (idx, expected) = live[p]
                let newValue = Int(rng.next() % 32)
                let old = try slab.update(at: idx, with: newValue)
                #expect(old == expected)
                live[p].value = newValue
                updates += 1
            } else {
                // PEEK a random live slot (non-destructive); must equal the oracle.
                let p = Int(rng.next() % UInt64(live.count))
                let (idx, expected) = live[p]
                let peeked = slab.peek(at: idx)
                #expect(peeked == expected)
            }
        }

        // Drain the remainder by index: every surviving index still returns its value
        // (the ultimate stable-index assertion after a long reuse-heavy history).
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

        // Shape sanity: the workload genuinely exercised every op and hit capacity.
        #expect(inserts >= 200)
        #expect(removes >= 60)
        #expect(updates >= 30)
        #expect(fullHits >= 1)          // fill/drain cycling reached a full slab
    }
}
