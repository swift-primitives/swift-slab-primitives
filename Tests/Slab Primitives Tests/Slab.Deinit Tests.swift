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

@Suite("Slab - Deinit")
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
