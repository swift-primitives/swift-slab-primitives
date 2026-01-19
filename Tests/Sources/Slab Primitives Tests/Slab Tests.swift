// Slab Tests.swift
// Tests for Slab fixed-capacity memory storage.

import Testing

@testable import Slab_Primitives

@Suite
struct `Slab - Storage Primitives` {

    // MARK: - Initialization

    @Test
    func `init - creates slab with capacity`() throws {
        let slab = try Slab<Int>(capacity: 10)
        #expect(slab.capacity == 10)
    }

    @Test
    func `init - zero capacity succeeds`() throws {
        let slab = try Slab<Int>(capacity: 0)
        #expect(slab.capacity == 0)
    }

    @Test
    func `init - negative capacity throws`() {
        #expect(throws: Slab<Int>.Error.invalidCapacity) {
            _ = try Slab<Int>(capacity: -1)
        }
    }

    // MARK: - Lifecycle Management

    @Test
    func `initialize and deinitialize - roundtrip`() throws {
        var slab = try Slab<Int>(capacity: 3)
        slab.initialize(at: 0, to: 42)
        let value = slab.deinitialize(at: 0)
        #expect(value == 42)
    }

    @Test
    func `initialize - multiple slots`() throws {
        var slab = try Slab<Int>(capacity: 3)
        slab.initialize(at: 0, to: 10)
        slab.initialize(at: 1, to: 20)
        slab.initialize(at: 2, to: 30)

        #expect(slab.deinitialize(at: 0) == 10)
        #expect(slab.deinitialize(at: 1) == 20)
        #expect(slab.deinitialize(at: 2) == 30)
    }

    // MARK: - Pointer Access

    @Test
    func `withUnsafePointer - reads value`() throws {
        var slab = try Slab<Int>(capacity: 1)
        slab.initialize(at: 0, to: 42)

        let value = slab.withUnsafePointer(at: 0) { $0.pointee }
        #expect(value == 42)

        _ = slab.deinitialize(at: 0)
    }

    @Test
    func `withUnsafeMutablePointer - modifies value`() throws {
        var slab = try Slab<Int>(capacity: 1)
        slab.initialize(at: 0, to: 42)

        slab.withUnsafeMutablePointer(at: 0) { $0.pointee = 100 }

        let value = slab.deinitialize(at: 0)
        #expect(value == 100)
    }
}
