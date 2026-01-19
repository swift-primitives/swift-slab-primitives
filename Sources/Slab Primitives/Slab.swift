// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-standards open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-standards project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif os(Windows)
    import ucrt
    import WinSDK
#endif

// MARK: - Global Sentinel for Empty Slabs

/// Process-global sentinel pointer for empty slabs.
///
/// ## Safety Rationale
///
/// Using a globally-allocated sentinel instead of `bitPattern` provides defense in depth:
/// - If an invariant is violated and the pointer is dereferenced, it points to valid memory
/// - `bitPattern` would give undefined behavior if dereferenced
/// - Matches Swift stdlib pattern (`_emptyBufferStorage`)
/// - Allocation is negligible (one global per process, amortized to zero)
///
/// Page-aligned pointer dominates all power-of-two alignments (1, 2, 4, 8, 16, ...).
/// For any `Element` type with standard alignment, this sentinel satisfies alignment requirements.
/// Allocated once at process start; never freed.
@usableFromInline
nonisolated(unsafe) let _emptySlabSentinel: UnsafeMutableRawPointer = {
    #if os(Windows)
        var info = SYSTEM_INFO()
        GetSystemInfo(&info)
        let pageSize = Int(info.dwPageSize)
        guard let raw = unsafe _aligned_malloc(1, pageSize) else {
            fatalError("Failed to allocate empty slab sentinel")
        }
        return unsafe raw
    #else
        let pageSize = sysconf(Int32(_SC_PAGESIZE))
        let alignment = pageSize > 0 ? Int(pageSize) : 4096
        var raw: UnsafeMutableRawPointer?
        let result = unsafe posix_memalign(&raw, alignment, 1)
        guard result == 0, let p = unsafe raw else {
            fatalError("Failed to allocate empty slab sentinel")
        }
        return unsafe p
    #endif
}()

/// A fixed-capacity, typed memory slab with manual element lifecycle.
@safe
public struct Slab<Element: ~Copyable>: ~Copyable {
    @usableFromInline
    var storage: UnsafeMutablePointer<Element>

    /// The number of slots in the slab.
    public let capacity: Int

    /// Creates a slab with the specified capacity.
    @inlinable
    public init(capacity: Int) throws(Slab.Error) {
        guard capacity >= 0 else {
            throw .invalidCapacity
        }

        if capacity == 0 {
            // Use global sentinel for empty slabs - provides defense in depth over bitPattern
            unsafe self.storage = _emptySlabSentinel.assumingMemoryBound(to: Element.self)
            self.capacity = 0
            return
        }

        let storage = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
        unsafe self.storage = storage
        self.capacity = capacity
    }

    deinit {
        if capacity > 0 {
            unsafe storage.deallocate()
        }
    }
}

// MARK: - Lifecycle Management (Checked)

extension Slab {
    /// Initializes the slot at the given index.
    ///
    /// - Parameters:
    ///   - index: The slot index to initialize.
    ///   - value: The value to store.
    /// - Throws: `Slab.Error.indexOutOfBounds` if the index is invalid.
    @inlinable
    public mutating func initialize(at index: Int, to value: consuming Element) throws(Error) {
        guard index >= 0 && index < capacity else {
            throw .indexOutOfBounds(index: index, capacity: capacity)
        }
        unsafe (storage + index).initialize(to: value)
    }

    /// Deinitializes the slot at the given index and returns its value.
    ///
    /// - Parameter index: The slot index to deinitialize.
    /// - Returns: The value that was stored at the index.
    /// - Throws: `Slab.Error.indexOutOfBounds` if the index is invalid.
    @inlinable
    public mutating func deinitialize(at index: Int) throws(Error) -> Element {
        guard index >= 0 && index < capacity else {
            throw .indexOutOfBounds(index: index, capacity: capacity)
        }
        return unsafe (storage + index).move()
    }
}

// MARK: - Lifecycle Management (Unchecked)

extension Slab {
    /// Initializes the slot at the given index without bounds checking.
    ///
    /// Use this when the index has already been validated by an invariant.
    ///
    /// - Parameters:
    ///   - index: The slot index to initialize. Must be in `0..<capacity`.
    ///   - value: The value to store.
    /// - Precondition: `index >= 0 && index < capacity`
    @inlinable
    public mutating func initialize(__unchecked index: Int, to value: consuming Element) {
        precondition(index >= 0 && index < capacity)
        unsafe (storage + index).initialize(to: value)
    }

    /// Deinitializes the slot at the given index and returns its value without bounds checking.
    ///
    /// Use this when the index has already been validated by an invariant.
    ///
    /// - Parameter index: The slot index to deinitialize. Must be in `0..<capacity`.
    /// - Returns: The value that was stored at the index.
    /// - Precondition: `index >= 0 && index < capacity`
    @inlinable
    public mutating func deinitialize(__unchecked index: Int) -> Element {
        precondition(index >= 0 && index < capacity)
        return unsafe (storage + index).move()
    }
}

// MARK: - Pointer Access

extension Slab {
    @unsafe
    @inlinable
    public func withUnsafePointer<R, E: Swift.Error>(
        at index: Int,
        _ body: (UnsafePointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        precondition(index >= 0 && index < capacity)
        return try unsafe body(storage + index)
    }

    @unsafe
    @inlinable
    public mutating func withUnsafeMutablePointer<R, E: Swift.Error>(
        at index: Int,
        _ body: (UnsafeMutablePointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        precondition(index >= 0 && index < capacity)
        return try unsafe body(storage + index)
    }
}

// MARK: - Sendable

extension Slab: @unchecked Sendable where Element: Sendable {}
