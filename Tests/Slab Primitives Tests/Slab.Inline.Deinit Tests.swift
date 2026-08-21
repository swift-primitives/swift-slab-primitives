import Slab_Inline_Primitive
import Testing

@testable import Slab_Primitives

@Suite(
    .disabled(
        if: !_isDebugAssertConfiguration(),
        "release-blocked: swift-issue-inlinearray-class-field-write-elision (Slab<E>.Inline inline arm); pending HANDOFF-sparse-occupancy-placement.md"
    )
)
struct `Slab.Inline.Deinit Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}

    final class Tracker: @unchecked Sendable {
        private var _storage: [Int] = []
    }

    struct Tracked: ~Copyable {
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
            var slab = Slab<Tracked>.Inline<4>()
            try slab.insert(Tracked(1, tracker: tracker))
            try slab.insert(Tracked(2, tracker: tracker))
            try slab.insert(Tracked(3, tracker: tracker))
        }
        #expect(tracker.count == 3)
    }

    @Test
    func `Inline empty deinit does not crash`() {
        do {
            let _ = Slab<Tracked>.Inline<4>()
        }
    }
}

extension `Slab.Inline.Deinit Tests`.Tracker {
    var count: Int { _storage.count }
    var order: [Int] { _storage }
    func append(_ id: Int) { _storage.append(id) }
}
