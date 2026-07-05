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

// The single ratified column: the canonical `Slab<E>` front door rides the DIRECT,
// heap-allocated, fixed-capacity Slab buffer (`Buffer.Slab.Bounded`, move-only). No
// `Shared` (CoW) column is pulled (no live consumer), so the slab family has one tower
// subject: `tower.direct`.
//
// `stdlib` is a hand-written slab over `Swift.Array<Int?>` + a free-list — the honest
// reference, since the standard library ships no slab / slot store. Both do O(1)
// consumer-index insert/remove with slot reuse; the delta is the tower's bitmap
// occupancy + typed-slot seam machinery vs the plain `[Int?]` array + `[Int]` free-list.

typealias TowerSlab = Slab<Int>

/// A textbook Vec + free-list slab over `Swift.Array` — the `stdlib` reference subject
/// (the classic Rust-`slab`-crate shape). O(1) insert (reuse-or-append) and remove.
struct StdSlab {
    var slots: [Int?] = []
    var freeList: [Int] = []

    var isEmpty: Bool { slots.count == freeList.count }

    mutating func reserve(_ n: Int) {
        slots.reserveCapacity(n)
        freeList.reserveCapacity(n)
    }

    @discardableResult
    mutating func insert(_ value: Int) -> Int {
        if let i = freeList.popLast() {
            slots[i] = value
            return i
        }
        slots.append(value)
        return slots.count - 1
    }

    mutating func remove(at i: Int) -> Int {
        let v = slots[i]!
        slots[i] = nil
        freeList.append(i)
        return v
    }

    mutating func removeAllOccupied() -> Int {
        var acc = 0
        for i in 0..<slots.count {
            if let v = slots[i] {
                acc &+= v
                slots[i] = nil
            }
        }
        return acc
    }
}
