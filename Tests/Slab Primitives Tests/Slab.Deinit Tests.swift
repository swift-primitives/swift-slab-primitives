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

// RELEASE-GUARD (swift-institute/Issues/swift-issue-inlinearray-class-field-write-elision):
// `Slab.Static` is backed by `Buffer.Slab.Inline`, whose occupancy-bitmap writes are elided
// under `-O` (the inline-arm release miscompile). These Static-deinit tests run in DEBUG and
// SKIP under `-O`, pending the occupancy-placement ruling (HANDOFF-sparse-occupancy-placement.md).
// (Base heap `Slab` is release-correct and covered by the "Slab" suite.)
@Suite(
    "Slab - Deinit",
    .disabled(
        if: !_isDebugAssertConfiguration(),
        "release-blocked: swift-issue-inlinearray-class-field-write-elision (Slab.Static inline arm); pending HANDOFF-sparse-occupancy-placement.md"
    )
)
struct SlabDeinitTests {

    final class Tracker: @unchecked Sendable {
        private var _storage: [Int] = []
        var count: Int { _storage.count }
        var deinitOrder: [Int] { _storage }
        func append(_ id: Int) { _storage.append(id) }
    }

    struct TrackedElement: ~Copyable {
        let id: Int
        let tracker: Tracker
        init(_ id: Int, tracker: Tracker) {
            self.id = id
            self.tracker = tracker
        }
        deinit { tracker.append(id) }
    }

    @Test
    func `Static deinit destroys all elements`() throws {
        let tracker = Tracker()
        do {
            var slab = Slab<TrackedElement>.Static<4>()
            try slab.insert(TrackedElement(1, tracker: tracker))
            try slab.insert(TrackedElement(2, tracker: tracker))
            try slab.insert(TrackedElement(3, tracker: tracker))
        }
        #expect(tracker.count == 3)
    }

    @Test
    func `Static empty deinit does not crash`() {
        do {
            let _ = Slab<TrackedElement>.Static<4>()
        }
    }
}
