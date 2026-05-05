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

import Index_Primitives
public import Slab_Primitives_Core

// MARK: - Non-Destructive Read

extension Slab.Indexed where Element: Copyable, Tag: ~Copyable {
    /// Returns the element at the specified slot without removing it.
    @inlinable
    public func peek(at index: Index<Tag>) -> Element? {
        _base.peek(at: index.retag(Element.self))
    }
}

// MARK: - Drain (Moved from Core to avoid constraint poisoning on nested types)

extension Slab.Indexed where Element: Copyable, Tag: ~Copyable {
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

extension Slab.Indexed: Sequence.Drain.`Protocol` {
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        _base.drain(body)
    }
}
