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

import Slab_Primitives

extension Bench {

    /// The slab family's hot ops (§9.5): first-vacant insert, addressed drain.
    ///
    /// The tower `Slab` is move-only and FIXED-CAPACITY, so a persistent subject cannot
    /// be copied to reset between reps — every rep builds a fresh slab sized to `n`. Two
    /// shapes isolate the costs:
    ///
    /// - `insert.zero`: n first-vacant inserts from empty (bitmap first-vacant scan +
    ///   typed-slot initialize). One op = one insert (`opsPerBatch = reps * n`).
    /// - `drain.cycle`: n inserts THEN a full consuming drain (every occupied slot moved
    ///   out). One op = one insert+drain element lifecycle (`opsPerBatch = reps * n`);
    ///   the drain cost is `drain.cycle - insert.zero`.
    ///
    /// ATTRIBUTION: the tower insert path is a bitmap first-vacant scan (`firstVacant()`,
    /// O(word)) + a typed-slot `initialize(at:to:)` seam write + an occupancy-bitmap flip;
    /// the `stdlib` reference is a Vec + free-list slab (`[Int?]` append/`popLast`). Both
    /// are O(1)-class per op; the delta is the bitmap+seam machinery vs the plain-array
    /// append + optional-tag. This is the honest reference (the stdlib ships no slab).
    static func slabCases() -> [Result] {
        var results: [Result] = []
        for n in sizes {
            let reps = Swift.max(1, structureOpsTarget / n)
            let ops = reps * n
            let seed = opaque(1)

            // Pre-generated workload: a fixed, checked-in value stream.
            let values: [Int] = (0..<n).map { ($0 &* 2_654_435_761) & 0x7fff_ffff }

            // Runtime `n` -> `Count` uses the throwing (validating) init, not the SLI
            // literal path; `n` is always a valid non-negative size here.
            let cap = try! Index<Int>.Count(n)

            // MARK: insert.zero (n first-vacant inserts from empty)

            results.append(Result(
                name: "insert.zero", subject: "tower.direct", n: n, opsPerBatch: ops,
                perOpNs: sample(opsPerBatch: ops) {
                    var acc = 0
                    for _ in 0..<reps {
                        var s = TowerSlab(minimumCapacity: cap)
                        for v in values {
                            if let slot = s.firstVacant() {
                                s.insert(v &+ seed, __unchecked: slot)
                            }
                        }
                        acc &+= Int(clamping: s.count)
                    }
                    sink(acc)
                }
            ))

            results.append(Result(
                name: "insert.zero", subject: "stdlib", n: n, opsPerBatch: ops,
                perOpNs: sample(opsPerBatch: ops) {
                    var acc = 0
                    for _ in 0..<reps {
                        var s = StdSlab()
                        s.reserve(n)
                        for v in values { s.insert(v &+ seed) }
                        acc &+= s.slots.count
                    }
                    sink(acc)
                }
            ))

            // MARK: drain.cycle (build then drain all occupied slots)

            results.append(Result(
                name: "drain.cycle", subject: "tower.direct", n: n, opsPerBatch: ops,
                perOpNs: sample(opsPerBatch: ops) {
                    var acc = 0
                    for _ in 0..<reps {
                        var s = TowerSlab(minimumCapacity: cap)
                        for v in values {
                            if let slot = s.firstVacant() {
                                s.insert(v &+ seed, __unchecked: slot)
                            }
                        }
                        s.drain { acc &+= $0 }
                    }
                    sink(acc)
                }
            ))

            results.append(Result(
                name: "drain.cycle", subject: "stdlib", n: n, opsPerBatch: ops,
                perOpNs: sample(opsPerBatch: ops) {
                    var acc = 0
                    for _ in 0..<reps {
                        var s = StdSlab()
                        s.reserve(n)
                        for v in values { s.insert(v &+ seed) }
                        acc &+= s.removeAllOccupied()
                    }
                    sink(acc)
                }
            ))
        }
        return results
    }
}
