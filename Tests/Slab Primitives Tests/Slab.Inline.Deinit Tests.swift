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

import Slab_Inline_Primitive
import Testing

@testable import Slab_Primitives

// Migrated from the parked `Slab.Static` deinit suite at the W3 un-park (the type is re-derived
// as the `Slab<E>.Inline<n>` front-door alias, not resurrected).
//
// RELEASE-GUARD (swift-institute/Issues/swift-issue-inlinearray-class-field-write-elision):
// `Slab<E>.Inline<n>` is backed by `Buffer.Slab.Inline`, whose occupancy-bitmap writes are elided
// under `-O` (the inline-arm release miscompile). These deinit tests run in DEBUG and SKIP under
// `-O`, pending the occupancy-placement ruling (HANDOFF-sparse-occupancy-placement.md).
// (Base heap `Slab` is release-correct and covered by the "Slab" suite.)
@Suite(
    .disabled(
        if: !_isDebugAssertConfiguration(),
        "release-blocked: swift-issue-inlinearray-class-field-write-elision (Slab<E>.Inline inline arm); pending HANDOFF-sparse-occupancy-placement.md"
    )
)
struct `Slab.Inline.Deinit Tests` {

    final class Tracker: @unchecked Sendable {
        private var _storage: [Int] = []
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
    func `Inline deinit destroys all elements`() throws {
        let tracker = Tracker()
        do {
            var slab = Slab<TrackedElement>.Inline<4>()
            try slab.insert(TrackedElement(1, tracker: tracker))
            try slab.insert(TrackedElement(2, tracker: tracker))
            try slab.insert(TrackedElement(3, tracker: tracker))
        }
        #expect(tracker.count == 3)
    }

    @Test
    func `Inline empty deinit does not crash`() {
        do {
            let _ = Slab<TrackedElement>.Inline<4>()
        }
    }
}

extension `Slab.Inline.Deinit Tests`.Tracker {
    var count: Int { _storage.count }
    var deinitOrder: [Int] { _storage }
    func append(_ id: Int) { _storage.append(id) }
}
