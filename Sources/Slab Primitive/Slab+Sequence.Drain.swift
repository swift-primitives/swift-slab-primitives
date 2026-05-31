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

import Buffer_Slab_Primitives
public import Property_Primitives
public import Sequence_Primitives

// MARK: - Drain (Consuming Iteration)

extension Slab where Element: ~Copyable {
    /// Consuming iteration over all occupied slots.
    @inlinable
    public var drain: Property<Sequence.Drain, Self>.Inout {
        mutating _read {
            yield Property<Sequence.Drain, Self>.Inout(&self)
        }
        mutating _modify {
            var accessor = Property<Sequence.Drain, Self>.Inout(&self)
            yield &accessor
        }
    }
}

extension Slab: Sequence.Drain.`Protocol` where Element: ~Copyable {
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        _buffer.drain(body)
    }
}
